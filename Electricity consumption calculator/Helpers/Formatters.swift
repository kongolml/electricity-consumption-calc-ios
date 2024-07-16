//
//  Formatters.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//

import Foundation

// Configuring the NumberFormatter for float values
// formatter for watt/kwatt fields
var floatNumberFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 4
    return formatter
}
