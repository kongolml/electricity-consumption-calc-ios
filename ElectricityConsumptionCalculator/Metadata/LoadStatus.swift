//
//  LoadStatus.swift
//  Electricity consumption calculator
//
//  Load status enum for gauge color coding and status display
//

import SwiftUI

enum LoadStatus: Equatable {
    case normal    // 0-60%
    case caution   // 60-80%
    case highLoad  // 80-100%
    case overload  // >100%

    var color: Color {
        switch self {
        case .normal:
            return .green
        case .caution:
            return .yellow
        case .highLoad:
            return .orange
        case .overload:
            return .red
        }
    }

    var accessibilityLabel: LocalizedStringResource {
        switch self {
        case .normal:
            return "Load status normal"
        case .caution:
            return "Load status caution"
        case .highLoad:
            return "Load status high"
        case .overload:
            return "Load status overload"
        }
    }

    var shortLabel: LocalizedStringResource {
        switch self {
        case .normal:
            return "Normal"
        case .caution:
            return "Caution"
        case .highLoad:
            return "High Load"
        case .overload:
            return "Overload"
        }
    }

    var emoji: String {
        switch self {
        case .normal:
            return "✅"
        case .caution:
            return "⚠️"
        case .highLoad:
            return "🔶"
        case .overload:
            return "🛑"
        }
    }
}
