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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var persistenceController: PersistenceController

    @State var showDeleteConfirmationAlert: Bool = false
    @State private var showAdvancedFields: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $consumer.name)

                    HStack {
                        EnergyInput(entityProperty: $consumer.consumption, placeholder: "Consumption")
                    }

                    HStack {
                        TextField("Quantity", value: $consumer.quantity, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                    }

                    Picker("Category", selection: $consumer.category) {
                        ForEach(DeviceCategory.allCases) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Priority", selection: $consumer.priorityType) {
                        ForEach(ConsumerPriorityType.allCases, id: \.self) { priorityType in
                            Text(priorityType.name).tag(priorityType.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundStyle(.gray)

                    Toggle("Enabled", isOn: $consumer.isActive)
                        .foregroundColor(.gray)
                }

                // Advanced Fields
                Section {
                    DisclosureGroup("Advanced", isExpanded: $showAdvancedFields) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Surge Wattage
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Surge Wattage")
                                    .font(.subheadline)
                                Text("Startup/surge power (0 = same as running)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                EnergyInput(entityProperty: $consumer.surgeWattage, placeholder: "Surge Watts")
                            }

                            // Power Factor
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Power Factor")
                                    .font(.subheadline)
                                Text("Efficiency multiplier (0.5 - 1.0)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Slider(value: $consumer.powerFactor, in: 0.5...1.0, step: 0.05)
                                HStack {
                                    Text("0.5")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.2f", consumer.powerFactor))
                                        .font(.subheadline)
                                    Spacer()
                                    Text("1.0")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // Duty Cycle
                            Picker("Duty Cycle", selection: $consumer.dutyCycleType) {
                                ForEach(DutyCycleType.allCases) { dutyCycle in
                                    Text(dutyCycle.name).tag(dutyCycle.rawValue)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section {
                    Button("Delete", role: .destructive) {
                        showDeleteConfirmationAlert = true
                    }
                    .confirmationDialog("Are you sure you want to delete this item?", isPresented: $showDeleteConfirmationAlert, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            showDeleteConfirmationAlert = false
                            persistenceController.deleteItem(consumer: consumer)
                            dismiss()
                        }
                    }
                }
            }
            .onDisappear {
                saveChanges()
            }
        }
        .navigationTitle(consumer.name)
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
