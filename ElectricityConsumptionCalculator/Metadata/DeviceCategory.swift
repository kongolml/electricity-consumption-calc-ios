//
//  DeviceCategory.swift
//  Electricity consumption calculator
//
//  Device categories for organizing consumer presets
//

import Foundation

enum DeviceCategory: Int16, CaseIterable, Identifiable {
    case lighting = 0
    case heating = 1
    case cooling = 2
    case kitchen = 3
    case tools = 4
    case electronics = 5
    case waterPumps = 6
    case medical = 7
    case other = 8
    
    var id: Int16 { self.rawValue }
    
    var name: LocalizedStringResource {
        switch self {
        case .lighting:
            return "Category_Lighting"
        case .heating:
            return "Category_Heating"
        case .cooling:
            return "Category_Cooling"
        case .kitchen:
            return "Category_Kitchen"
        case .tools:
            return "Category_Tools"
        case .electronics:
            return "Category_Electronics"
        case .waterPumps:
            return "Category_WaterPumps"
        case .medical:
            return "Category_Medical"
        case .other:
            return "Category_Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .lighting:
            return "lightbulb"
        case .heating:
            return "flame"
        case .cooling:
            return "snowflake"
        case .kitchen:
            return "fork.knife"
        case .tools:
            return "wrench"
        case .electronics:
            return "tv"
        case .waterPumps:
            return "drop"
        case .medical:
            return "cross.case"
        case .other:
            return "powerplug"
        }
    }
}
