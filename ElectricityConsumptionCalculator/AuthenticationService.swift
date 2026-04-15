//
//  AuthenticationService.swift
//  Electricity consumption calculator
//
//  Refactored for better architecture
//

import Foundation
import Alamofire
import os

/// Response model for authentication tokens
struct AccessTokens: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int? // Token lifetime in seconds

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

/// Service for managing authentication operations
final class AuthenticationService: AuthenticationServiceProtocol, ObservableObject {
    static let shared = AuthenticationService()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "Auth")
    
    private init() {}
    
    /// Sign in with Google ID token and exchange for API access tokens
    /// - Parameters:
    ///   - idToken: The Google ID token from successful sign-in
    ///   - completion: Completion handler with access tokens or error
    func signInWithGoogleToken(idToken: String, completion: @escaping (AccessTokens?, Error?) -> Void) {
        let endpoint = "\(Api.baseApiUrl)/auth/google/signin"
        
        let parameters: [String: String] = [
            "idToken": idToken
        ]
        
        AlamofireService.sharedSession.request(
            endpoint,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .validate()
        .responseDecodable(of: AccessTokens.self) { [weak self] response in
            switch response.result {
            case .success(let tokens):
                completion(tokens, nil)
            case .failure(let error):
                self?.logger.error("Authentication failed: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    /// Refresh access token using refresh token
    /// - Parameters:
    ///   - refreshToken: The refresh token
    ///   - completion: Completion handler with new access tokens or error
    func refreshToken(refreshToken: String, completion: @escaping (AccessTokens?, Error?) -> Void) {
        let endpoint = "\(Api.baseApiUrl)/auth/refresh"
        
        let parameters: [String: String] = [
            "refreshToken": refreshToken
        ]
        
        AlamofireService.sharedSession.request(
            endpoint,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .validate()
        .responseDecodable(of: AccessTokens.self) { [weak self] response in
            switch response.result {
            case .success(let tokens):
                completion(tokens, nil)
            case .failure(let error):
                self?.logger.error("Token refresh failed: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
}
