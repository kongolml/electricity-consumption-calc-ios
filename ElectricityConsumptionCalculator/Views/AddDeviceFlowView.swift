//
//  AddDeviceFlowView.swift
//  Electricity consumption calculator
//
//  Sheet for adding a device from presets or custom
//

import SwiftUI

struct AddDeviceFlowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var persistenceController: PersistenceController

    let generator: GeneratorEntity
    let onDeviceAdded: (() -> Void)?

    @State private var selectedCategory: DeviceCategory?
    @State private var selectedPreset: DevicePreset?
    @State private var showCustomForm = false

    init(generator: GeneratorEntity, onDeviceAdded: (() -> Void)? = nil) {
        self.generator = generator
        self.onDeviceAdded = onDeviceAdded
    }

    var body: some View {
        NavigationStack {
            Group {
                if let preset = selectedPreset {
                    // Show preset confirmation/customization
                    PresetConfirmationView(
                        preset: preset,
                        generator: generator,
                        onSave: {
                            onDeviceAdded?()
                            dismiss()
                        },
                        onCancel: {
                            selectedPreset = nil
                        }
                    )
                } else if let category = selectedCategory {
                    // Show presets for selected category
                    PresetListView(category: category) { preset in
                        selectedPreset = preset
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Back") {
                                selectedCategory = nil
                            }
                        }
                    }
                } else if showCustomForm {
                    // Show custom device form
                    CustomDeviceFormView(
                        generator: generator,
                        onSave: {
                            onDeviceAdded?()
                            dismiss()
                        },
                        onCancel: {
                            showCustomForm = false
                        }
                    )
                } else {
                    // Show category selection
                    PresetCategoryListView { category in
                        selectedCategory = category
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Custom") {
                                showCustomForm = true
                            }
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var navigationTitle: String {
        if selectedPreset != nil {
            return "Confirm Device"
        } else if selectedCategory != nil {
            return selectedCategory.map { String(localized: $0.name) } ?? "Devices"
        } else if showCustomForm {
            return "Custom Device"
        } else {
            return "Add Device"
        }
    }
}

// MARK: - Preset Confirmation View

private struct PresetConfirmationView: View {
    let preset: DevicePreset
    let generator: GeneratorEntity
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var persistenceController: PersistenceController

    @State private var priority: ConsumerPriorityType = .important
    @State private var quantity: Int16 = 1
    @State private var isActive: Bool = true

    var body: some View {
        Form {
            Section(header: Text("Device Details")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(LocalizedStringKey(preset.name))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Category")
                    Spacer()
                    Label(preset.deviceCategory.name, systemImage: preset.deviceCategory.iconName)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Consumption")
                    Spacer()
                    Text("\(Int(preset.consumption)) W")
                        .foregroundStyle(.secondary)
                }

                if preset.surgeWattage > preset.consumption {
                    HStack {
                        Text("Surge")
                        Spacer()
                        Text("\(Int(preset.surgeWattage)) W")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section(header: Text("Configuration")) {
                Picker("Priority", selection: $priority) {
                    ForEach(ConsumerPriorityType.allCases, id: \.self) { p in
                        Text(p.name).tag(p)
                    }
                }

                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)

                Toggle("Active", isOn: $isActive)
            }

            Section {
                Button("Add Device") {
                    saveDevice()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.blue)

                Button("Choose Different") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func saveDevice() {
        let consumer = preset.createConsumer(in: viewContext, for: generator)
        consumer.priorityType = priority.rawValue
        consumer.quantity = quantity
        consumer.isActive = isActive

        persistenceController.saveContext()
        onSave()
    }
}

// MARK: - Custom Device Form

private struct CustomDeviceFormView: View {
    let generator: GeneratorEntity
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var persistenceController: PersistenceController

    @State private var name: String = ""
    @State private var consumption: Double = 0
    @State private var category: DeviceCategory = .other
    @State private var priority: ConsumerPriorityType = .important
    @State private var quantity: Int16 = 1

    var body: some View {
        Form {
            Section(header: Text("Basic Information")) {
                TextField("Device Name", text: $name)

                Picker("Category", selection: $category) {
                    ForEach(DeviceCategory.allCases) { cat in
                        Label(cat.name, systemImage: cat.iconName).tag(cat)
                    }
                }

                HStack {
                    Text("Consumption")
                    Spacer()
                    EnergyInput(entityProperty: $consumption, placeholder: "Watts")
                }
            }

            Section(header: Text("Configuration")) {
                Picker("Priority", selection: $priority) {
                    ForEach(ConsumerPriorityType.allCases, id: \.self) { p in
                        Text(p.name).tag(p)
                    }
                }

                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
            }

            Section {
                Button("Add Device") {
                    saveDevice()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.blue)
                .disabled(name.isEmpty || consumption <= 0)

                Button("Cancel") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func saveDevice() {
        let consumer = ConsumerEntity(context: viewContext)
        consumer.name = name
        consumer.consumption = consumption
        consumer.category = category.rawValue
        consumer.priorityType = priority.rawValue
        consumer.quantity = quantity
        consumer.isActive = true
        consumer.relationship = generator
        consumer.timeCreated = Date()
        consumer.powerFactor = 1.0
        consumer.surgeWattage = 0
        consumer.dutyCycleType = DutyCycleType.manualOnOff.rawValue

        persistenceController.saveContext()
        onSave()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let generator = GeneratorEntity.createMock(context: context)

    return AddDeviceFlowView(generator: generator)
        .environment(\.managedObjectContext, context)
}
