//
//  AuthenticationServiceProtocol.swift
//  Electricity consumption calculator
//
//  Protocol for authentication operations to enable dependency injection and testing
//

import Foundation

/// Protocol for authentication operations
protocol AuthenticationServiceProtocol {
    /// Sign in with Google ID token and exchange for API access tokens
    /// - Parameters:
    ///   - idToken: The Google ID token from successful sign-in
    ///   - completion: Completion handler with access tokens or error
    func signInWithGoogleToken(idToken: String, completion: @escaping (AccessTokens?, Error?) -> Void)
    
    /// Refresh access token using refresh token
    /// - Parameters:
    ///   - refreshToken: The refresh token
    ///   - completion: Completion handler with new access tokens or error
    func refreshToken(refreshToken: String, completion: @escaping (AccessTokens?, Error?) -> Void)
}
