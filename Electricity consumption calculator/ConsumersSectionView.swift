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
        consumersList.filter { $0.isActive }.map { $0.consumption * Double($0.quantity) }.reduce(0, +)
    }
    
    var sectionPriorityGroup: String {
        consumersList.isEmpty ? "No items to display" : ConsumerPriorityType.init(rawValue: consumersList[0].priorityType)?.description ?? "Basic group"
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
            .onDelete(perform: deleteItemsInBulk)
            .onMove(perform: moveItems)
        }, header: {
            Text("\(sectionPriorityGroup) item\(consumersList.count > 1 ? "s" : "")")
        }, footer: {
            Text("Total: \(String(format: "%.2f", consumersTotalConsumption)) Watt")
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
    
    private func deleteItemsInBulk(offsets: IndexSet) {
        viewContext.perform {
            offsets.map { consumersList[$0] }.forEach { consumer in
                viewContext.delete(consumer)
            }
            
            persistenceController.saveContext()
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        var revisedItems = consumersList.map { $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination)

        for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
            revisedItems[reverseIndex].orderInGroup = Int16(reverseIndex)
        }

        viewContext.perform {
            persistenceController.saveContext()
        }
    }
}

#Preview {
    @Environment(\.managedObjectContext) var viewContext

    @State var dummyConsumers = [
        ConsumerEntity.createMock(context: viewContext),
        ConsumerEntity.createMock(context: viewContext),
        ConsumerEntity.createMock(context: viewContext),
        ConsumerEntity.createMock(context: viewContext),
        ConsumerEntity.createMock(context: viewContext),
        ConsumerEntity.createMock(context: viewContext),
        ConsumerEntity.createMock(context: viewContext)
    ]

    return List{ConsumersSectionView(consumersList: $dummyConsumers)}
}
