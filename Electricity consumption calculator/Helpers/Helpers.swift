//
//  Helpers.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//

import Foundation

func convertEnergyDoubleToNiceFormat(value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 0
    formatter.usesGroupingSeparator = false
    
    return formatter.string(from: value as NSNumber) ?? ""
}
