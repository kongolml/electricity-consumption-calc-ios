//
//  ContentView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
//    TODO: remove this to normal place:
    @State var myCapacity: Double = 500
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var persistenceController: PersistenceController

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ConsumerEntity.orderInGroup, ascending: true)],
        animation: .default)
    private var allGeneratorConsumers: FetchedResults<ConsumerEntity>
    
    var totalConsumption: Double {
        return allGeneratorConsumers.filter { $0.isActive }.map { $0.consumption * Double($0.quantity) }.reduce(0, +)
    }
    
    var leftCapacity: Double {
        myCapacity - totalConsumption
    }
    
    private func filteredItems(for category: ConsumerPriorityType) -> [ConsumerEntity] {
        return allGeneratorConsumers.filter { $0.priorityType == category.rawValue }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(ConsumerPriorityType.allCases, id: \.self) { filteredConsumersGroup in
                    let consumersInGroup = filteredItems(for: filteredConsumersGroup)

                    Section(content: {
                        ForEach(consumersInGroup, id: \.self) { consumerItem in
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
                    }, header: {
                        Text("\(filteredConsumersGroup.description) item\(consumersInGroup.count > 1 ? "s" : "")")
                    }, footer: {
                        var consumersTotalConsumption: Double {
                            consumersInGroup.filter { $0.isActive }.map { $0.consumption * Double($0.quantity) }.reduce(0, +)
                        }
                        Text("Total: \(consumersTotalConsumption, specifier: "%.2f")Watt")
                    })
                }
                
                Section(content: {
                    HStack {
                        Text("My capacity")
                        TextField("420", value: $myCapacity, format: FloatingPointFormatStyle())
                        Text("Watt")
                    }
                    Text("Total consumption \(String(format: "%.2f", totalConsumption)) Watt")
                    Text("Left capacity \(String(format: "%.2f", leftCapacity)) Watt")
                })
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Menu {
                        Button(action: {
                            addINewtem(priority: .main)
                        }) {
                            Label("Main device", systemImage: "refrigerator")
                        }
                        
                        Button(action: {
                            addINewtem(priority: .secondary)
                        }) {
                            Label("Secondary device", systemImage: "lightbulb.2")
                        }
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func addINewtem(priority: ConsumerPriorityType) {
        viewContext.perform {
            withAnimation {
                let newItem = ConsumerEntity(context: viewContext)
                newItem.priorityType = priority.rawValue
                
                persistenceController.saveContext()
            }
        }
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
//            offsets.map { consumersList[$0] }.forEach { consumer in
//                viewContext.delete(consumer)
//            }
            
            persistenceController.saveContext()
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
//        var revisedItems = consumersList.map { $0 }
//        revisedItems.move(fromOffsets: source, toOffset: destination)
//
//        for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
//            revisedItems[reverseIndex].orderInGroup = Int16(reverseIndex)
//        }

        viewContext.perform {
            persistenceController.saveContext()
        }
    }
}

#Preview {
    @Environment(\.managedObjectContext) var viewContext
    return ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
