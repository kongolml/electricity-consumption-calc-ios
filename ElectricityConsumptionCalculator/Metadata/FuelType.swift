//
//  FuelType.swift
//  Electricity consumption calculator
//
//  Fuel types for generator fuel estimation
//

import Foundation

enum FuelType: Int16, CaseIterable, Identifiable {
    case none = 0
    case gasoline = 1
    case diesel = 2
    case propane = 3
    
    var id: Int16 { self.rawValue }
    
    var name: LocalizedStringResource {
        switch self {
        case .none:
            return "FuelType_None"
        case .gasoline:
            return "FuelType_Gasoline"
        case .diesel:
            return "FuelType_Diesel"
        case .propane:
            return "FuelType_Propane"
        }
    }
    
    /// Default fuel consumption rate in liters per kWh
    var defaultConsumptionRate: Double {
        switch self {
        case .none:
            return 0.0
        case .gasoline:
            return 0.35
        case .diesel:
            return 0.25
        case .propane:
            return 0.45
        }
    }
}
