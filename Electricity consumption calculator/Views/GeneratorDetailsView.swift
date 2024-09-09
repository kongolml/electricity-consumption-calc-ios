//
//  GeneratorDetailsView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//

import SwiftUI

struct GeneratorDetailsView: View {
    @Environment(\.managedObjectContext) private var viewContext
//    @EnvironmentObject var persistenceController: PersistenceController
    @EnvironmentObject var generatorViewModel: GeneratorViewModel
//    @StateObject private var generatorViewModel: ConsumerViewModel
    @State private var formHasChanges: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    struct DefaultGeneratorValues {
        var name: String
        var capacity: Double
    }
    // Track initial values for change detection
    @State private var initialValues = DefaultGeneratorValues(name: "", capacity: 1000)
    
    @State private var preferredConsumptionUnit: ConsumptionUnits = .watt
    
//    let generatorId: String
    
//    init(generatorId: UUID) {
//        self.generatorId = generatorId.uuidString
//    }
    
    private func checkForFormChanges() {
        formHasChanges = (
            generatorViewModel.name != initialValues.name ||
            generatorViewModel.capacity != initialValues.capacity
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(content: {
                    TextField("Name", text: $generatorViewModel.name)
                        .onChange(of: generatorViewModel.name) {
                            checkForFormChanges()
                        }
                    EnergyInput(entityProperty: $generatorViewModel.capacity, placeholder: "Capacity")
                        .onChange(of: generatorViewModel.capacity) {
                            checkForFormChanges()
                        }
                })
            }
            .toolbar {
                ToolbarItem {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!formHasChanges)
                }
            }
        }
        .navigationTitle(generatorViewModel.name)
        .navigationBarTitleDisplayMode(.inline)
//        .onDisappear {
//            saveChanges()
//        }
    }
    
    private func saveChanges() {
        print("generatorViewModel.updateGenerator()")
        generatorViewModel.updateGenerator()
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    return GeneratorDetailsView()
}
