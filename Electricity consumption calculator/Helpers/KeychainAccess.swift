//
//  KeychainAccess.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 15.07.2024.
//

import Foundation
import KeychainAccess


enum KeychainKeys: String {
    case googleIdToken = "googleIdToken"
    case userAccessTokenApi = "userAccessTokenApi"
    case refreshToken = "refreshToken"
    case tokenExpiration = "tokenExpiration"
}

class KeychainToolbox {
    // Private keychain instance per service
    private let authKeychain = Keychain(service: "com.electricitycalculator.auth")
        .synchronizable(false)
        .accessibility(.afterFirstUnlock)
    
    func setItem(value: String, key: KeychainKeys) {
        if value.isEmpty {
            debugPrint("no value was provided for setting")
            return
        }

        do {
            try authKeychain.set(value, key: key.rawValue)
        } catch let error {
            print("Error saving item to keychain")
            debugPrint(error)
        }
    }
    
    func setGoogleIdToken(value: String) {
        do {
            try authKeychain.set(value, key: KeychainKeys.googleIdToken.rawValue)
        } catch let error {
            print("Error saving item to keychain")
            debugPrint(error)
        }
    }
    
    func getGoogleIdToken() -> String? {
        let googleIdToken = try? authKeychain.getString(KeychainKeys.googleIdToken.rawValue)
        
        return googleIdToken
    }
    
    func setUserApiToken(newToken: String) {
        setItem(value: newToken, key: .userAccessTokenApi)
    }
    
    func getUserApiToken() -> String? {
        do {
            return try authKeychain.getString(KeychainKeys.userAccessTokenApi.rawValue)
        } catch {
            print("Error retrieving user API token from keychain")
            debugPrint(error)
            return nil
        }
    }
    
//    
    func setRefreshToken(value: String) {
        do {
            try authKeychain.set(value, key: KeychainKeys.refreshToken.rawValue)
        } catch let error {
            print("Error saving refresh token to keychain")
            debugPrint(error)
        }
    }

    func getRefreshToken() -> String? {
        do {
            return try authKeychain.getString(KeychainKeys.refreshToken.rawValue)
        } catch {
            print("Error retrieving refresh token from keychain")
            debugPrint(error)
            return nil
        }
    }

    func clearGoogleIdToken() {
        do {
            try authKeychain.remove(KeychainKeys.googleIdToken.rawValue)
        } catch let error {
            print("Error removing Google ID token from keychain")
            debugPrint(error)
        }
    }

    func clearUserApiToken() {
        do {
            try authKeychain.remove(KeychainKeys.userAccessTokenApi.rawValue)
        } catch let error {
            print("Error removing user API token from keychain")
            debugPrint(error)
        }
    }

    func clearRefreshToken() {
        do {
            try authKeychain.remove(KeychainKeys.refreshToken.rawValue)
        } catch let error {
            print("Error removing refresh token from keychain")
            debugPrint(error)
        }
    }

    func clearAllTokens() {
        clearGoogleIdToken()
        clearUserApiToken()
        clearRefreshToken()
        clearTokenExpiration()
    }

    // MARK: - Token Expiration

    func setTokenExpiration(expirationDate: Date) {
        do {
            let timestamp = expirationDate.timeIntervalSince1970
            try authKeychain.set(String(timestamp), key: KeychainKeys.tokenExpiration.rawValue)
        } catch let error {
            print("Error saving token expiration to keychain")
            debugPrint(error)
        }
    }

    func getTokenExpiration() -> Date? {
        do {
            guard let timestampString = try authKeychain.getString(KeychainKeys.tokenExpiration.rawValue),
                  let timestamp = Double(timestampString) else {
                return nil
            }
            return Date(timeIntervalSince1970: timestamp)
        } catch {
            print("Error retrieving token expiration from keychain")
            debugPrint(error)
            return nil
        }
    }

    func clearTokenExpiration() {
        do {
            try authKeychain.remove(KeychainKeys.tokenExpiration.rawValue)
        } catch let error {
            print("Error removing token expiration from keychain")
            debugPrint(error)
        }
    }

    /// Validates if the current token is still valid (not expired with 5-minute buffer)
    func isTokenValid() -> Bool {
        guard let expiration = getTokenExpiration() else {
            // No expiration set, assume token might be valid
            return getUserApiToken() != nil
        }
        // Add 5-minute buffer to refresh before actual expiration
        let buffer: TimeInterval = 5 * 60
        return Date().addingTimeInterval(buffer) < expiration
    }
}
