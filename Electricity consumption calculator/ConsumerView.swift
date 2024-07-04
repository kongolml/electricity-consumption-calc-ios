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

    @State var showDeleteConfirmationAlert: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Name")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Teapot", text: $consumer.name)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150)
                    }
                    HStack {
                        Text("Consumption (Watt)")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("100", value: $consumer.consumption, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150)
                    }
                    HStack {
                        Text("Quantity")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Quantity", value: $consumer.quantity, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150)
                    }
                    
                    Picker("Type", selection: $consumer.priorityType) {
                        ForEach(ConsumerPriorityType.allCases, id: \.self) { priorityType in
                            Text(priorityType.description)
                        }
                    }
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
                            print("TODO: delete item and bo back")
                            showDeleteConfirmationAlert = false
                            print("TODO: go back to prev view")
//                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navigationTitle(consumer.name)
        }
        .onDisappear {
            
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let dummyConsumer = ConsumerEntity(context: context)
    
    return ConsumerView(consumer: dummyConsumer)
}
