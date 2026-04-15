//
//  AccountViewModel.swift
//  Electricity consumption calculator
//
//  ViewModel for AccountView — owns authentication state and logic
//

import Foundation
import Observation
import GoogleSignIn
import os

// Protocol wrapper for Google Sign-In to enable testing
protocol GoogleSignInServiceProtocol {
    var currentUser: GIDGoogleUser? { get }
    func signOut()
}

// Wrapper for the real Google Sign-In SDK
struct GoogleSignInService: GoogleSignInServiceProtocol {
    var currentUser: GIDGoogleUser? {
        GIDSignIn.sharedInstance.currentUser
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}

@Observable
final class AccountViewModel {
    // MARK: - State
    var isSignedIn: Bool = false
    var isSigningIn: Bool = false
    var authError: String?
    var userName: String?
    var userEmail: String?
    var userProfileImageURL: URL?

    // MARK: - Dependencies
    private let keychainService: KeychainServiceProtocol
    private let authenticationService: AuthenticationServiceProtocol
    private let googleSignInService: GoogleSignInServiceProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "AccountViewModel")
    
    private var authFailureObserver: NSObjectProtocol?

    // MARK: - Init
    init(keychainService: KeychainServiceProtocol,
         authenticationService: AuthenticationServiceProtocol,
         googleSignInService: GoogleSignInServiceProtocol = GoogleSignInService()) {
        self.keychainService = keychainService
        self.authenticationService = authenticationService
        self.googleSignInService = googleSignInService
        checkExistingAuth()
        setupNotifications()
    }
    
    deinit {
        if let observer = authFailureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupNotifications() {
        authFailureObserver = NotificationCenter.default.addObserver(
            forName: .authenticationFailed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.warning("Authentication failed notification received, signing out")
            self?.signOut()
        }
    }

    // MARK: - Auth

    private func checkExistingAuth() {
        isSignedIn = keychainService.isTokenValid()
        updateGoogleUserInfo()
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
                DispatchQueue.main.async {
                    self?.authError = error.localizedDescription
                    self?.isSigningIn = false
                }
                return
            }
            guard let user else {
                DispatchQueue.main.async {
                    self?.isSigningIn = false
                }
                return
            }
            guard let idToken = user.idToken?.tokenString else {
                self?.logger.error("No ID token available from Google Sign-In")
                DispatchQueue.main.async {
                    self?.isSigningIn = false
                }
                return
            }

            self?.exchangeGoogleToken(idToken: idToken)
        }
    }

    private func exchangeGoogleToken(idToken: String) {
        authenticationService.signInWithGoogleToken(idToken: idToken) { [weak self] tokens, error in
            if let error {
                self?.logger.error("Auth exchange failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.authError = error.localizedDescription
                    self?.isSigningIn = false
                }
                return
            }
            guard let tokens else {
                self?.logger.error("No tokens received from authentication service")
                DispatchQueue.main.async {
                    self?.isSigningIn = false
                }
                return
            }

            self?.keychainService.setUserApiToken(newToken: tokens.accessToken)
            self?.logger.info("Access token saved successfully")

            if let refreshToken = tokens.refreshToken {
                self?.keychainService.setRefreshToken(value: refreshToken)
                self?.logger.info("Refresh token saved successfully")
            }

            let expiresIn = tokens.expiresIn ?? 3600
            let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
            self?.keychainService.setTokenExpiration(expirationDate: expirationDate)
            self?.logger.info("Token expiration saved: \(expirationDate)")

            DispatchQueue.main.async {
                self?.isSignedIn = true
                self?.isSigningIn = false
                self?.authError = nil
                self?.updateGoogleUserInfo()
            }
        }
    }

    func signOut() {
        isSigningIn = false
        googleSignInService.signOut()
        keychainService.clearAllTokens()
        isSignedIn = false
        authError = nil
        userName = nil
        userEmail = nil
        userProfileImageURL = nil
        logger.info("User signed out, all tokens cleared")
    }

    // MARK: - Private Helpers

    private func updateGoogleUserInfo() {
        guard let googleUser = googleSignInService.currentUser else {
            userName = nil
            userEmail = nil
            userProfileImageURL = nil
            return
        }
        userName = googleUser.profile?.name
        userEmail = googleUser.profile?.email
        userProfileImageURL = googleUser.profile?.imageURL(withDimension: 100)
    }
}