//
//  DutyCycleType.swift
//  Electricity consumption calculator
//
//  Duty cycle types for runtime estimation
//

import Foundation

enum DutyCycleType: Int16, CaseIterable, Identifiable {
    case alwaysOn = 1
    case cyclesAutomatically = 2
    case manualOnOff = 3
    
    var id: Int16 { self.rawValue }
    
    var name: LocalizedStringResource {
        switch self {
        case .alwaysOn:
            return "DutyCycle_AlwaysOn"
        case .cyclesAutomatically:
            return "DutyCycle_CyclesAutomatically"
        case .manualOnOff:
            return "DutyCycle_ManualOnOff"
        }
    }
    
    /// Estimated duty cycle factor (0.0 - 1.0) for runtime calculations
    var estimatedDutyFactor: Double {
        switch self {
        case .alwaysOn:
            return 1.0
        case .cyclesAutomatically:
            return 0.5 // Assumes 50% runtime for cycling devices like fridges
        case .manualOnOff:
            return 1.0 // Manual control - assume full when active
        }
    }
}
