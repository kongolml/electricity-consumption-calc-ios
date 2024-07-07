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
    
    // Configuring the NumberFormatter for float values
    private var floatNumberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
        return formatter
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $consumer.name)
                    HStack {
                        TextField("Consumption", value: Binding(
                            get: {
                                consumer.consumption * preferredConsumptionUnit.conversionFactor
                            },
                            set: { newValue in
                                consumer.consumption = newValue / preferredConsumptionUnit.conversionFactor
                                
                            }
                        ), formatter: floatNumberFormatter)
                        .keyboardType(.decimalPad)
                        .onChange(of: consumer.consumption, {
                            print(consumer)
                        })
                        
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
                    HStack {
                        TextField("Quantity", value: $consumer.quantity, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Type", selection: $consumer.priorityType) {
                        ForEach(ConsumerPriorityType.allCases, id: \.self) { priorityType in
                            Text(priorityType.description).tag(priorityType.rawValue)
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
            .navigationTitle(consumer.name)
            .onDisappear {
                saveChanges()
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
    
    let dummyConsumer = ConsumerEntity(context: context)
    
    return ConsumerView(consumer: dummyConsumer)
}
