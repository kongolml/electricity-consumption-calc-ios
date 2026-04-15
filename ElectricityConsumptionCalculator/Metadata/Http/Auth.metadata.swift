//
//  Auth.metadata.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 16.07.2024.
//

import Foundation

struct UserAuthTokensFromServer: Decodable {
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
    }
}

struct SignInGooglePayload: Codable {
    let idToken: String;
    
    enum CodingKeys: String, CodingKey {
        case idToken
    }
}
