//
//  GeneratorDetailsView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//

import SwiftUI

struct GeneratorDetailsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var persistenceController: PersistenceController
    @EnvironmentObject var generatorViewModel: GeneratorViewModel
    
    @State private var preferredConsumptionUnit: ConsumptionUnits = .watt
    
//    let generatorId: String
    
//    init(generatorId: UUID) {
//        self.generatorId = generatorId.uuidString
//    }

    var body: some View {
        NavigationStack {
            Form {
                Section(content: {
                    TextField("Name", text: $generatorViewModel.name)
                    EnergyInput(entityProperty: $generatorViewModel.capacity, placeholder: "Capacity")
                })
            }
        }
        .navigationTitle(generatorViewModel.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            saveChanges()
        }
        
    }
    
    private func saveChanges() {
        print("generatorViewModel.updateGenerator()")
        generatorViewModel.updateGenerator()
    }
}

#Preview {
//    let context = PersistenceController.preview.container.viewContext
    
//    let dummyGenerator = GeneratorEntity.createMock(context: context)

    return GeneratorDetailsView()
}
