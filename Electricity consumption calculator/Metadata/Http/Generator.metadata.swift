//
//  Generator.metadata.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 27.07.2024.
//

import Foundation

struct GeneratorFromServer: Decodable {
    let name: String
    let consumers: [ConsumerHttpPayload]
    let capacity: Double
    let updatedAt: Date
    let id: String
    
//    enum CodingKeys: String, CodingKey {
//        case accessToken
//        case refreshToken
//    }
}
