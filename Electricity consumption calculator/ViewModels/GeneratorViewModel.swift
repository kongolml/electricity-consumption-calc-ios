//
//  GeneratorViewModel.swift
//  Electricity consumption calculator
//
//  ViewModel for GeneratorView — owns all business logic
//

import Foundation
import Observation
import GoogleSignIn
import os

@Observable
final class GeneratorViewModel {
    // MARK: - State
    var isSignedIn: Bool = false
    var isSigningIn: Bool = false
    var authError: String?

    // MARK: - Dependencies
    private let keychainService: KeychainServiceProtocol
    private let authenticationService: AuthenticationServiceProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "GeneratorViewModel")

    // MARK: - Init
    init(keychainService: KeychainServiceProtocol,
         authenticationService: AuthenticationServiceProtocol) {
        self.keychainService = keychainService
        self.authenticationService = authenticationService
        checkExistingAuth()
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .authenticationFailed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.warning("Authentication failed notification received, signing out")
            self?.signOut()
        }
    }

    // MARK: - Auth

    func checkExistingAuth() {
        isSignedIn = keychainService.isTokenValid()
    }

    func handleGoogleSignInResult(signInResult: GIDSignInResult?, error: Error?) {
        if let error {
            logger.error("Sign in failed: \(error.localizedDescription)")
            authError = error.localizedDescription
            isSigningIn = false
            return
        }
        guard let signInResult else {
            isSigningIn = false
            return
        }

        signInResult.user.refreshTokensIfNeeded { [weak self] user, error in
            if let error {
                self?.logger.error("Token refresh failed: \(error.localizedDescription)")
                self?.authError = error.localizedDescription
                self?.isSigningIn = false
                return
            }
            guard let user else {
                self?.isSigningIn = false
                return
            }
            guard let idToken = user.idToken?.tokenString else {
                self?.logger.error("No ID token available from Google Sign-In")
                self?.isSigningIn = false
                return
            }

            self?.exchangeGoogleToken(idToken: idToken)
        }
    }

    func exchangeGoogleToken(idToken: String) {
        authenticationService.signInWithGoogleToken(idToken: idToken) { [weak self] tokens, error in
            if let error {
                self?.logger.error("Auth exchange failed: \(error.localizedDescription)")
                self?.authError = error.localizedDescription
                self?.isSigningIn = false
                return
            }
            guard let tokens else {
                self?.logger.error("No tokens received from authentication service")
                self?.isSigningIn = false
                return
            }

            self?.keychainService.setUserApiToken(newToken: tokens.accessToken)
            self?.logger.info("Access token saved successfully")

            if let refreshToken = tokens.refreshToken {
                self?.keychainService.setRefreshToken(value: refreshToken)
                self?.logger.info("Refresh token saved successfully")
            }

            // Store token expiration if provided, default to 1 hour if not
            let expiresIn = tokens.expiresIn ?? 3600
            let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
            self?.keychainService.setTokenExpiration(expirationDate: expirationDate)
            self?.logger.info("Token expiration saved: \(expirationDate)")

            self?.isSignedIn = true
            self?.isSigningIn = false
            self?.authError = nil
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        keychainService.clearAllTokens()
        isSignedIn = false
        authError = nil
        logger.info("User signed out, all tokens cleared")
    }
}
