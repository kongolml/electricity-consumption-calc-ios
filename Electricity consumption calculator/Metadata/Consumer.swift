//
//  Consumer.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import Foundation

enum ConsumerPriorityType: Int16, CaseIterable {
    case main = 1
    case secondary = 2
    
    var description: String {
        switch self {
        case .main:
            return "Main"
        case .secondary:
            return "Secondary"
        }
    }
}
