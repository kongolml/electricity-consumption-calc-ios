//
//  Formatters.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//

import Foundation

/// Centralized formatters for the application
enum Formatters {
    /// Formatter for watt/kWatt fields with up to 4 decimal places
    static let floatNumber: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
        return formatter
    }()

    /// Formatter for energy display with up to 2 decimal places
    static let energyDisplay: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    /// Formats an energy value for display
    static func formatEnergy(_ value: Double) -> String {
        energyDisplay.string(from: value as NSNumber) ?? ""
    }
}
