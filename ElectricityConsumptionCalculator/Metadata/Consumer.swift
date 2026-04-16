//
//  Consumer.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import Foundation

enum ConsumerPriorityType: Int16, CaseIterable {
    case critical = 1
    case important = 2
    case optional = 3

    var name: LocalizedStringResource {
        switch self {
        case .critical:
            return "Critical"
        case .important:
            return "Important"
        case .optional:
            return "Optional"
        }
    }

    var namePlural: LocalizedStringResource {
        switch self {
        case .critical:
            return "Critical_plural"
        case .important:
            return "Important_plural"
        case .optional:
            return "Optional_plural"
        }
    }
}

enum ConsumptionUnits: Int, CaseIterable, Identifiable {
    case watt = 1
    case kwatt = 2
    
    var id: Int { self.rawValue }
    
    var name: LocalizedStringResource {
        switch self {
        case .watt:
            return "Watt"
        case .kwatt:
            return "kWatt"
        }
    }
    
    var conversionFactor: Double {
        switch self {
        case .watt:
            return 1.0
        case .kwatt:
            return 0.001
        }
    }
}
