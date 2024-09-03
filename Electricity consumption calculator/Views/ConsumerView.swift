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
    @FocusState private var isNameFieldFocused: Bool
//    @State private var preferredConsumptionUnit: ConsumptionUnits = .watt
    
//    let consumerId: String

    init(consumerId: UUID, isNewConsumer: Bool? = false) {
//        let model = ConsumerViewModel(context: PersistenceController.shared.container.viewContext)
//        _consumerViewModel = StateObject(wrappedValue: model)

//        self.consumerId = consumerId.uuidString
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
//        self.isNewConsumer = isNewConsumer ?? false
    }
    
//    init() {
//        let model = ConsumerViewModel(context: PersistenceController.shared.container.viewContext)
//        model.setCurrentConsumer(consumer: <#T##ConsumerEntity#>)
//        _consumerViewModel = StateObject(wrappedValue: model)
//    }

    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: $consumerViewModel.name)
                        .focused($isNameFieldFocused)
                        .onAppear {
                            // Set the focus when the view appears
                            isNameFieldFocused = isNewConsumer
                        }
                    HStack {
                        EnergyInput(entityProperty: $consumerViewModel.consumption, placeholder: "Consumption")
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
//            .navigationTitle($consumerViewModel.name)
        }
        .toolbar {
            ToolbarItem {
                Button("Save") {
                    saveChanges()
                }
            }
        }
//        .navigationTitle("hallos")
//        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveChanges() {
        consumerViewModel.updateConsumer()

        if isNewConsumer {
            presentationMode.wrappedValue.dismiss()
        }
//        if viewContext.hasChanges{
            consumerViewModel.updateConsumer()
//        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let dummyConsumer = ConsumerEntity(context: context)
    
    return ConsumerView(consumerId: dummyConsumer.id)
}
