//
//  Generator.metadata.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 27.07.2024.
//

import Foundation

struct GeneratorFromServer: Decodable {
    let name: String
    let consumers: [ConsumerFromServer]
    let capacity: Double
    let updatedAt: Date
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case consumers
        case capacity
        case updatedAt
        case id
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.consumers = try container.decode([ConsumerFromServer].self, forKey: .consumers)
        self.capacity = try container.decode(Double.self, forKey: .capacity)
        self.id = try container.decode(String.self, forKey: .id)
//        self.quantity = try container.decode(Int16.self, forKey: .quantity)
//        self.orderInGroup = try container.decode(Int16.self, forKey: .orderInGroup)
//        self.id = try container.decode(String.self, forKey: .id)
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
