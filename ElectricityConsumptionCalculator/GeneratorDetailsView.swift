//
//  GeneratorDetailsView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//

import SwiftUI

struct GeneratorDetailsView: View {
    @ObservedObject var generator: GeneratorEntity
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var persistenceController: PersistenceController
    
    @State private var showFuelSection: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Basic Information
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $generator.name)
                    TextField("Brand (optional)", text: Binding(
                        get: { generator.brand ?? "" },
                        set: { generator.brand = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                // Capacity
                Section(header: Text("Capacity")) {
                    HStack {
                        Text("Running Capacity")
                        Spacer()
                        EnergyInput(entityProperty: $generator.capacity, placeholder: "Watts")
                    }
                    HStack {
                        Text("Peak/Surge Capacity")
                        Spacer()
                        EnergyInput(entityProperty: $generator.peakCapacity, placeholder: "Watts")
                    }
                    
                    if generator.peakCapacity > 0 {
                        Text("Peak capacity is used for surge protection calculations")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Fuel Configuration
                Section(header: Text("Fuel Configuration"), footer: fuelFooter) {
                    Toggle("Enable Fuel Tracking", isOn: Binding(
                        get: { generator.fuelTankCapacity > 0 },
                        set: { isEnabled in
                            if isEnabled && generator.fuelTankCapacity == 0 {
                                generator.fuelTankCapacity = 15 // Default 15L
                                generator.fuelConsumptionRate = 0.35 // Default gasoline rate
                                generator.fuelType = 1 // Gasoline
                            } else if !isEnabled {
                                generator.fuelTankCapacity = 0
                            }
                        }
                    ))
                    
                    if generator.fuelTankCapacity > 0 {
                        HStack {
                            Text("Tank Capacity")
                            Spacer()
                            HStack(spacing: 4) {
                                TextField("Liters", value: $generator.fuelTankCapacity, formatter: NumberFormatter())
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("L")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Picker("Fuel Type", selection: $generator.fuelType) {
                            ForEach(FuelType.allCases) { fuelType in
                                Text(fuelType.name).tag(fuelType.rawValue)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        HStack {
                            Text("Consumption Rate")
                            Spacer()
                            HStack(spacing: 4) {
                                TextField("L/kWh", value: $generator.fuelConsumptionRate, formatter: NumberFormatter())
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("L/kWh")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Show default rate hint
                        if let selectedFuel = FuelType(rawValue: generator.fuelType),
                           abs(generator.fuelConsumptionRate - selectedFuel.defaultConsumptionRate) > 0.001 {
                            Button("Use default for \(selectedFuel.name)") {
                                generator.fuelConsumptionRate = selectedFuel.defaultConsumptionRate
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle(generator.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            saveChanges()
        }
    }
    
    private var fuelFooter: some View {
        Group {
            if generator.fuelTankCapacity > 0 {
                Text("Fuel tracking enables runtime estimation based on current load.")
            }
        }
    }
    
    private func saveChanges() {
        viewContext.perform {
            persistenceController.saveContext()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let dummyGenerator = GeneratorEntity.createMock(context: context)

    return GeneratorDetailsView(generator: dummyGenerator)
}
