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
    
    var name: LocalizedStringResource {
        switch self {
        case .main:
            return "Main"
        case .secondary:
            return "Secondary"
        }
    }
    
    var namePlural: LocalizedStringResource {
        switch self {
        case .main:
            return "Main_plural"
        case .secondary:
            return "Secondary_plural"
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
