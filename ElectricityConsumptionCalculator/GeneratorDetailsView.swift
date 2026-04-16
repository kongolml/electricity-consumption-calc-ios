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

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $generator.name)
                }

                Section(header: Text("Capacity")) {
                    HStack {
                        Text("Running Capacity")
                        Spacer()
                        EnergyInput(entityProperty: $generator.capacity, placeholder: "Watts")
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
