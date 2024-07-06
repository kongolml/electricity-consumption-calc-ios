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
    
    @StateObject private var contextObserver: ContextObserver
    init(context: NSManagedObjectContext) {
        _contextObserver = StateObject(wrappedValue: ContextObserver(context: context))
    }
    
    @State private var mainConsumersList: [ConsumerEntity] = []
    var mainConsumers: [ConsumerEntity] {
        allGeneratorConsumers.filter { consumer in
            return consumer.priorityType == ConsumerPriorityType.main.rawValue
        }
    }
    
    @State private var secondaryConsumersList: [ConsumerEntity] = []
    var secondaryConsumers: [ConsumerEntity] {
        allGeneratorConsumers.filter { consumer in
            return consumer.priorityType == ConsumerPriorityType.secondary.rawValue
        }
    }
    
    var totalConsumption: Double {
        return allGeneratorConsumers.filter { $0.isActive }.map { $0.consumption * Double($0.quantity) }.reduce(0, +)
//        return 1023.2
    }
    
    var leftCapacity: Double {
        myCapacity - totalConsumption
    }
    
    
    var groupedItems: [(String, [ConsumerEntity])] {
        Dictionary(grouping: allGeneratorConsumers, by: { $0.priorityType.description })
            .sorted(by: { $0.key < $1.key })
    }
    
    
    private var test: [ConsumerEntity] {
        allGeneratorConsumers.filter { consumer in
            return consumer.priorityType == ConsumerPriorityType.main.rawValue
        }
    }
    

    var body: some View {
        NavigationView {
            List {
                ConsumersSectionView(consumersList: $mainConsumersList)
                ConsumersSectionView(consumersList: $secondaryConsumersList)
//                ConsumersSectionView(consumersList: $test)
//                ForEach(ConsumerPriorityType.allCases, id: \.self) { itemPriorityType in
//                    let consumersWithThisPriority = allGeneratorConsumers.filter { consumer in
//                        return consumer.priorityType == itemPriorityType.rawValue
//                    }
//                    
//                    let thisPriorityTypeConsumersTotalConsumption = consumersWithThisPriority.filter { $0.isActive }.map { $0.consumption * Float($0.quantity) }.reduce(0, +)
//
//                    Section(content: {
//                        ForEach(consumersWithThisPriority, id: \.self) { consumerItem in
//                            NavigationLink {
//                                ConsumerView(consumer: consumerItem)
//                            } label: {
//                                ConsumerListItemView(consumer: consumerItem)
//                            }
//                            .swipeActions(edge: .leading) {
//                                Button(action: {
//                                    toggleItemActiveStatus(consumer: consumerItem)
//                                }) {
//                                    consumerItem.isActive ? Label("Activate", systemImage: "x.circle") : Label("Deactivate", systemImage: "checkmark.circle.fill")
//                                }
//                                .tint(consumerItem.isActive ? .red : .green)
//                            }
//                            .swipeActions(edge: .trailing) {
//                                Button(action: {
//                                    deleteItem(consumer: consumerItem)
//                                }) {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                                .tint(.red)
//                            }
//                        }
////                        .onDelete(perform: {
////                            deleteItemsInBulk(
////                        })
//                        .onMove(perform: moveItems)
//                    }, header: {
//                        Text("\(itemPriorityType.description) item\(consumersWithThisPriority.count > 1 ? "s" : "")")
//                    }, footer: {
//                        Text("Total: \(String(format: "%.2f", thisPriorityTypeConsumersTotalConsumption)) Watt")
//                    })
//                }
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
//        .onAppear {
//            mainConsumersList = mainConsumers
//            secondaryConsumersList = secondaryConsumers
//        }
        .onReceive(contextObserver.$didChange) { _ in
            updateMainConsumersList()
        }
//        .onChange(of: allGeneratorConsumers, perform: { _ in
//            mainConsumersList = mainConsumers
//        })
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
    
    private func updateMainConsumersList() {
        print("updagin mains")
        mainConsumersList = allGeneratorConsumers.filter { consumer in
            consumer.priorityType == ConsumerPriorityType.main.rawValue
        }
    }
}

#Preview {
    @Environment(\.managedObjectContext) var viewContext
    return ContentView(context: viewContext).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
