//
//  ConsumersSectionView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 05.07.2024.
//

import SwiftUI
import CoreData

struct ConsumersSectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var persistenceController: PersistenceController

    @Binding var consumersList: [ConsumerEntity]
    
    var consumersTotalConsumption: Double {
        ConsumptionCalculator.totalConsumption(for: consumersList)
    }
    
    var body: some View {
        Section(content: {
            ForEach(consumersList, id: \.self) { consumerItem in
                NavigationLink {
                    ConsumerView(consumer: consumerItem)
                } label: {
                    ConsumerListItemView(consumer: consumerItem)
                }
                .swipeActions(edge: .leading) {
                    Button(action: {
                        toggleItemActiveStatus(consumer: consumerItem)
                    }) {
                        consumerItem.isActive ? Label("Activate", systemImage: "x.circle") : Label("Deactivate", systemImage: "checkmark.circle.fill")
                    }
                    .tint(consumerItem.isActive ? .red : .green)
                }
                .swipeActions(edge: .trailing) {
                    Button(action: {
                        deleteItem(consumer: consumerItem)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }, footer: {
            Text("Total Consumption: \(consumersTotalConsumption, specifier: "%.2f")")
        })
    }
    
    private func toggleItemActiveStatus(consumer: ConsumerEntity) {
        viewContext.perform {
            consumer.isActive.toggle()
            
            persistenceController.saveContext()
        }
    }
    
    private func deleteItem(consumer: ConsumerEntity) {
        viewContext.perform {
            withAnimation {
                persistenceController.deleteItem(consumer: consumer)
            }
        }
    }
}
