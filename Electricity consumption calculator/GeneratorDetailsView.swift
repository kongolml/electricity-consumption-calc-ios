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
    
    @State private var preferredConsumptionUnit: ConsumptionUnits = .watt

    var body: some View {
        NavigationStack {
            Form {
                Section(content: {
                    TextField("Name", text: $generator.name)
                    EnergyInput(entityProperty: $generator.capacity, placeholder: "Capacity")
                })
                .navigationTitle(generator.name)
            }
        }
        .onDisappear {
            saveChanges()
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
