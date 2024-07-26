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
    let consumers: [Int]? // TODO: fix type here, maybe inherit from parent?
}

struct ConsumerHttpPayload: Encodable {
    let name: String?
    let consumption: Double?
    let isActive: Bool?
    let priorityType: PriorityType?
    let quantity: Int?
    let orderInGroup: Int?
}
