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
}

let keychain = Keychain(service: KeychainKeys.googleIdToken.rawValue)

class KeychainToolbox {
    func setItem(value: String, key: KeychainKeys) {
        if (value.isEmpty) {
            debugPrint("no value was provided for seting")
            return
        }

        do {
            try keychain.set(value, key: key.rawValue)
        } catch let error {
            print("Error saving item to keychain")
            debugPrint(error)
        }
    }
    
    func setGoogleIdToken(value: String) {
        do {
            try keychain.set(value, key: KeychainKeys.googleIdToken.rawValue)
        } catch let error {
            print("Error saving item to keychain")
            debugPrint(error)
        }
    }
    
    func getGoogleIdToken() -> String? {
        let googleIdToken = try? keychain.getString(KeychainKeys.googleIdToken.rawValue)
        
        return googleIdToken
    }
    
    func setUserApiToken(newToken: String) {
        setItem(value: newToken, key: .userAccessTokenApi)
    }
    
    func getUserApiToken() -> String? {
        let accessToken = try? keychain.getString(KeychainKeys.userAccessTokenApi.rawValue)
                
        return accessToken
//        return "TODO: HARDCODEDE TOKEN IS USER, GET REAL ONE"
    }
    
//    
//    func clearItem(key: KeychainKeys) {
//        do {
//            try keychain.remove(key.rawValue)
//        } catch let error {
//            print("Error removing item from keychain")
//            debugPrint(error)
//        }
//    }
//
//    func getUserTokenFromKeychain() -> String? {
//        let accessToken = try? keychain.getString(KeychainKeys.accessToken.rawValue)
//        
//        return accessToken
//    }
//    
//    
//    func getProviderTokenFromKeychain() -> String? {
//        let providerToken = try? keychain.getString(KeychainKeys.providerToken.rawValue)
//        
//        return providerToken
//    }
//    
//    func setProviderToken(newToken: String) {
//        setItem(value: newToken, key: .providerToken)
//    }
}
