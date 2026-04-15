//
//  EnergyInput.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//

import SwiftUI

struct EnergyInput: View {
    @State private var preferredConsumptionUnit: ConsumptionUnits = .watt
    @Binding var entityProperty: Double
    var placeholder: String

    var body: some View {
        HStack {
            TextField(placeholder, value: Binding(
                get: {
                    entityProperty * preferredConsumptionUnit.conversionFactor
                },
                set: { newValue in
                    entityProperty = newValue / preferredConsumptionUnit.conversionFactor
                    
                }
            ), formatter: Formatters.floatNumber)
            .keyboardType(.decimalPad)
            
            Menu {
                ForEach(ConsumptionUnits.allCases) { consumptionUnit in
                    Button(action: {
                        preferredConsumptionUnit = consumptionUnit
                    }) {
                        Text(consumptionUnit.name)
                    }
                }
            } label: {
                Text(preferredConsumptionUnit.name)
            }
        }
    }
}

#Preview {
    @State var val = 1000.0

    return EnergyInput(entityProperty: $val, placeholder: "Capacity")
}
