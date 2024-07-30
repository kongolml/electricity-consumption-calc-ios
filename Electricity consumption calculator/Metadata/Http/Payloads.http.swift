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
    let updatedAt: Date
//    let isDeleted: boolean
    
//    enum CodingKeys: String, CodingKey {
//        case accessToken
//        case refreshToken
//    }
    
    enum CodingKeys: CodingKey {
        case name
        case consumption
        case isActive
        case priorityType
        case quantity
        case orderInGroup
        case id
        case updatedAt
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.consumption = try container.decode(Double.self, forKey: .consumption)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.priorityType = try container.decode(PriorityType.self, forKey: .priorityType)
        self.quantity = try container.decode(Int16.self, forKey: .quantity)
        self.orderInGroup = try container.decode(Int16.self, forKey: .orderInGroup)
        self.id = try container.decode(String.self, forKey: .id)
//        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Adjust according to your date format
                guard let date = formatter.date(from: updatedAtString) else {
                    throw DecodingError.dataCorruptedError(forKey: .updatedAt,
                                                           in: container,
                                                           debugDescription: "Date string does not match format expected by formatter.")
                }
        self.updatedAt = date
    }
}
