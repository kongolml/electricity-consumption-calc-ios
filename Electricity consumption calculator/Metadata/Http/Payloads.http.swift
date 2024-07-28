//
//  Payloads.http.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 25.07.2024.
//

import Foundation

enum PriorityType: Int, Codable {
    case main = 1
    case secondary = 2
}

struct GeneratorHttpPayload: Encodable {
    let name: String
    let capacity: Double
    let consumers: [ConsumerHttpPayload]? // TODO: fix type here, maybe inherit from parent?
    let createdAt: Date?
    let updatedAt: Date
    
    init(from generatorEntity: GeneratorEntity) {
        self.name = generatorEntity.name
        self.capacity = generatorEntity.capacity
        self.updatedAt = generatorEntity.updatedAt
        // TODO: PASS CONSUMERS!!!!
        self.consumers = []
        self.createdAt = generatorEntity.createdAt
    }
}

struct ConsumerHttpPayload: Encodable, Decodable {
    let name: String?
    let consumption: Double?
    let isActive: Bool?
    let priorityType: PriorityType?
    let quantity: Int16?
    let orderInGroup: Int16?
//    let id: String?
    
    init(from consumerEntity: ConsumerEntity) {
        self.name = consumerEntity.name
        self.consumption = consumerEntity.consumption
        self.isActive = consumerEntity.isActive
        self.priorityType = PriorityType(rawValue: Int(consumerEntity.priorityType))
        self.quantity = consumerEntity.quantity
        self.orderInGroup = consumerEntity.orderInGroup
    }
}

struct ConsumerFromServer: Decodable {
    let name: String
    let consumption: Double
    let isActive: Bool
    let priorityType: PriorityType
    let quantity: Int16
    let orderInGroup: Int16
    let id: String
//    let isDeleted: boolean
    
//    enum CodingKeys: String, CodingKey {
//        case accessToken
//        case refreshToken
//    }
}
