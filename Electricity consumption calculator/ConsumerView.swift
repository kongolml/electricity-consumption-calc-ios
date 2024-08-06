//
//  ConsumerView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI

struct ConsumerView: View {
    @ObservedObject var consumer: ConsumerEntity
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var persistenceController: PersistenceController

    @State var showDeleteConfirmationAlert: Bool = false
    @State private var preferredConsumptionUnit: ConsumptionUnits = .watt

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $consumer.name)
                    HStack {
                        EnergyInput(entityProperty: $consumer.consumption, placeholder: "Consumption")
                    }
                    HStack {
                        TextField("Quantity", value: $consumer.quantity, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Type", selection: $consumer.priorityType) {
                        ForEach(ConsumerPriorityType.allCases, id: \.self) { priorityType in
                            Text(priorityType.name).tag(priorityType.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundStyle(.gray)
                    
                    Toggle("Enabled", isOn: $consumer.isActive)
                        .foregroundColor(.gray)
                }
                Section {
                    Button("Delete", role: .destructive) {
                        showDeleteConfirmationAlert = true
                    }
                    .confirmationDialog("Are you sure you want to delete this item?", isPresented: $showDeleteConfirmationAlert, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            showDeleteConfirmationAlert = false
                            persistenceController.deleteItem(consumer: consumer)
                            print("TODO: go back to prev view")
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .onDisappear {
                saveChanges()
            }
        }
        .navigationTitle(consumer.name)
//        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveChanges() {
        viewContext.perform {
            consumer.updatedAt = Date()
            persistenceController.saveContext()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let dummyConsumer = ConsumerEntity(context: context)
    
    return ConsumerView(consumer: dummyConsumer)
}
