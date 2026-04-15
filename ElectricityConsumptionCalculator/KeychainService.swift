//
//  KeychainService.swift
//  Electricity consumption calculator
//
//  Refactored for better architecture
//

import Foundation
import KeychainAccess

/// Protocol for keychain operations to enable dependency injection and testing
protocol KeychainServiceProtocol {
    func setGoogleIdToken(value: String)
    func getGoogleIdToken() -> String?
    func setUserApiToken(newToken: String)
    func getUserApiToken() -> String?
    func setRefreshToken(value: String)
    func getRefreshToken() -> String?
    func clearAllTokens()
    func setTokenExpiration(expirationDate: Date)
    func getTokenExpiration() -> Date?
    func isTokenValid() -> Bool
}

/// Service for managing keychain operations with proper singleton pattern
final class KeychainService: KeychainServiceProtocol, ObservableObject {
    static let shared = KeychainService()

    private let keychainToolbox = KeychainToolbox()

    private init() {}

    func setGoogleIdToken(value: String) {
        keychainToolbox.setGoogleIdToken(value: value)
    }

    func getGoogleIdToken() -> String? {
        keychainToolbox.getGoogleIdToken()
    }

    func setUserApiToken(newToken: String) {
        keychainToolbox.setUserApiToken(newToken: newToken)
    }

    func getUserApiToken() -> String? {
        keychainToolbox.getUserApiToken()
    }

    func setRefreshToken(value: String) {
        keychainToolbox.setRefreshToken(value: value)
    }

    func getRefreshToken() -> String? {
        keychainToolbox.getRefreshToken()
    }

    func clearAllTokens() {
        keychainToolbox.clearAllTokens()
    }

    func setTokenExpiration(expirationDate: Date) {
        keychainToolbox.setTokenExpiration(expirationDate: expirationDate)
    }

    func getTokenExpiration() -> Date? {
        keychainToolbox.getTokenExpiration()
    }

    func isTokenValid() -> Bool {
        keychainToolbox.isTokenValid()
    }
}
