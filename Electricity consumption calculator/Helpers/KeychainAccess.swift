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
    }
}
