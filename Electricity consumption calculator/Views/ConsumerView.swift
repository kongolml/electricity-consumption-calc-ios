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
    
    // Track initial values for change detection
    @State private var initialName: String = ""
    @State private var initialConsumption: Double = 0
    @State private var initialQuantity: Int16 = 0
    @State private var initialPriorityType: Int16 = 1
    @State private var initialIsActive: Bool = false

    init(consumerId: UUID, isNewConsumer: Bool? = false) {
        self.isNewConsumer = isNewConsumer ?? false
        
        let model = ConsumerViewModel(context: PersistenceController.shared.container.viewContext)
    
        model.fetchConsumerById(consumerId.uuidString)
        _consumerViewModel = StateObject(wrappedValue: model)
    }
    
    init(consumer: ConsumerEntity, isNewConsumer: Bool? = false) {
        let model = ConsumerViewModel(context: PersistenceController.shared.container.viewContext)
        model.setCurrentConsumer(consumer: consumer)
        _consumerViewModel = StateObject(wrappedValue: model)
        _isNewConsumer = State(initialValue: isNewConsumer ?? false)
    }
    
    private func checkForFormChanges() {
        formHasChanges = (
            consumerViewModel.name != initialName ||
            consumerViewModel.consumption != initialConsumption ||
            consumerViewModel.quantity != initialQuantity ||
            consumerViewModel.priorityType != initialPriorityType ||
            consumerViewModel.isActive != initialIsActive
        )
    }

    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: $consumerViewModel.name)
                        .focused($isNameFieldFocused)
                        .onAppear {
                            // Set the focus when the view appears
                            isNameFieldFocused = isNewConsumer
                            
                            // Initialize initial state
                            initialName = consumerViewModel.name
                            initialConsumption = consumerViewModel.consumption
                            initialQuantity = consumerViewModel.quantity
                            initialPriorityType = consumerViewModel.priorityType
                            initialIsActive = consumerViewModel.isActive
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
                    }

                    Picker("Type", selection: $consumerViewModel.priorityType) {
                        ForEach(ConsumerPriorityType.allCases, id: \.self) { priorityType in
                            Text(priorityType.name).tag(priorityType.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundStyle(.gray)

                    Toggle("Enabled", isOn: $consumerViewModel.isActive)
                        .foregroundColor(.gray)
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
//            .navigationTitle($consumerViewModel.name)
            .onDisappear {
//                if isNewConsumer && !viewContext.hasChanges {
//                    consumerViewModel.deleteConsumer()
//                }
//                if viewContext.hasChanges {
//                    print("saving changes")
//                    saveChanges()
//                }
            }
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
    
    private func saveChanges() {
        if formHasChanges {
            consumerViewModel.updateConsumer()
        }

        if isNewConsumer {
            presentationMode.wrappedValue.dismiss()
        }
//        if viewContext.hasChanges{
//            consumerViewModel.updateConsumer()
//        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let dummyConsumer = ConsumerEntity(context: context)
    
    return ConsumerView(consumerId: dummyConsumer.id)
}
