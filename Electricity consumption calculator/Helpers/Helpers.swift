//
//  Helpers.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//

import Foundation

/// Converts an energy value to a nicely formatted string
/// - Parameter value: The energy value to format
/// - Returns: A formatted string representation
func convertEnergyDoubleToNiceFormat(value: Double) -> String {
    Formatters.formatEnergy(value)
}
