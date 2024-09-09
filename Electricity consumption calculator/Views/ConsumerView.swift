//
//  ConsumerView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI

struct ConsumerNavigationItem: Hashable {
    let consumerId: UUID
    let isNewConsumer: Bool
}

struct ConsumerView: View {
    @StateObject private var consumerViewModel: ConsumerViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State var showDeleteConfirmationAlert: Bool = false
    @State private var isNewConsumer = false
    @State private var formHasChanges: Bool = false
    @FocusState private var isNameFieldFocused: Bool
//    @State private var preferredConsumptionUnit: ConsumptionUnits = .watt
    @State private var consumersSections: [ConsumerPriorityType: [ConsumerEntity]] = [:]
    
    struct DefaultConsumerValues {
        var name: String
        var consumption: Double
        var quantity: Int16
        var priorityType: ConsumerPriorityType
        var isActive: Bool
        var orderInGroup: Int16
    }
    
    // Track initial values for change detection
    @State private var initialValues = DefaultConsumerValues(name: "", consumption: 50, quantity: 1, priorityType: .main, isActive: true, orderInGroup: {
        return 99
    }())

    init(consumerId: UUID, isNewConsumer: Bool? = false) {
        self.isNewConsumer = isNewConsumer ?? false
        
        let model = ConsumerViewModel(context: PersistenceController.shared.container.viewContext)
    
        model.fetchConsumerById(consumerId.uuidString)
        _consumerViewModel = StateObject(wrappedValue: model)
    }
    
    init(consumer: ConsumerEntity, isNewConsumer: Bool? = false, consumersSections: [ConsumerPriorityType: [ConsumerEntity]]) {
        let model = ConsumerViewModel(context: PersistenceController.shared.container.viewContext)
        model.setCurrentConsumer(consumer: consumer)
        _consumerViewModel = StateObject(wrappedValue: model)
        _isNewConsumer = State(initialValue: isNewConsumer ?? false)
        _consumersSections = State(initialValue: consumersSections)
    }
    
    private func checkForFormChanges() {
        formHasChanges = (
            consumerViewModel.name != initialValues.name ||
            consumerViewModel.consumption != initialValues.consumption ||
            consumerViewModel.quantity != initialValues.quantity ||
            consumerViewModel.priorityType != initialValues.priorityType.rawValue ||
            consumerViewModel.isActive != initialValues.isActive
        )
    }
    
    private func setIntialState() {
        // Set the focus when the view appears
        isNameFieldFocused = isNewConsumer
        
        // Initialize initial state
        initialValues.name = consumerViewModel.name
        initialValues.consumption = consumerViewModel.consumption
        initialValues.quantity = consumerViewModel.quantity
        
//        TODO: this is mess with int/int16
//        let priorityTypeAsInt = Int(consumerViewModel.priorityType)
        initialValues.priorityType = ConsumerPriorityType(rawValue: consumerViewModel.priorityType) ?? .main //PriorityType(rawValue: Int(consumerViewModel.priorityType))
        initialValues.isActive = consumerViewModel.isActive
    }

    var body: some View {
        if consumerViewModel.currentConsumerIsSet {
            Form {
                Section {
                    TextField("Name", text: $consumerViewModel.name)
                        .focused($isNameFieldFocused)
                        .onAppear {
//                            UITextField.appearance().clearButtonMode = .whileEditing
                        }
                        .onChange(of: consumerViewModel.name) {
                            checkForFormChanges()
                        }
                    HStack {
                        EnergyInput(entityProperty: $consumerViewModel.consumption, placeholder: "Consumption")
                            .onChange(of: consumerViewModel.consumption) {
                                checkForFormChanges()
                            }
                    }
                    HStack {
                        TextField("Quantity", value: $consumerViewModel.quantity, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .onChange(of: consumerViewModel.quantity) {
                                checkForFormChanges()
                            }
                    }

                    Picker("Type", selection: $consumerViewModel.priorityType) {
                        ForEach(ConsumerPriorityType.allCases, id: \.self) { priorityType in
                            Text(priorityType.name).tag(priorityType.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundStyle(.gray)
                    .onChange(of: consumerViewModel.priorityType) {
                        checkForFormChanges()
                    }

                    Toggle("Enabled", isOn: $consumerViewModel.isActive)
                        .foregroundColor(.gray)
                        .onChange(of: consumerViewModel.isActive) {
                            checkForFormChanges()
                        }
                }
                
                if !isNewConsumer {
                    Section {
                        Button("Delete", role: .destructive) {
                            showDeleteConfirmationAlert = true
                        }
                        .confirmationDialog("Are you sure you want to delete this item?", isPresented: $showDeleteConfirmationAlert, titleVisibility: .visible) {
                            Button("Delete", role: .destructive) {
                                showDeleteConfirmationAlert = false
                                consumerViewModel.deleteConsumer()
                                
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
            .onAppear {
                setIntialState()
            }
            .toolbar {
                ToolbarItem {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!formHasChanges)
                }
            }
        } else {
            ProgressView("Loading consumer")
        }
        
//            .onDisappear {
//                if isNewConsumer && !viewContext.hasChanges {
//                    consumerViewModel.deleteConsumer()
//                }
//                if viewContext.hasChanges {
//                    print("saving changes")
//                    saveChanges()
//                }
//            }
    }
    
    private func saveChanges() {
        if isNewConsumer {
//            we need to calculate its order in group
            let consumerPriorityType = ConsumerPriorityType(rawValue: consumerViewModel.priorityType) ?? .main
            let consumersInGroup = self.consumersSections[consumerPriorityType]?.count ?? 0
            consumerViewModel.orderInGroup = Int16(consumersInGroup)
        }
        
        if formHasChanges {
            consumerViewModel.updateConsumer()
        }

        if isNewConsumer {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let dummyConsumer = ConsumerEntity(context: context)
    
    return ConsumerView(consumerId: dummyConsumer.id)
}
