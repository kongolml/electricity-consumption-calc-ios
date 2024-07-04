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
    @State var myCapacity: Float = 500
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ConsumerEntity.timeCreated, ascending: true)],
        animation: .default)
    private var allGeneratorConsumers: FetchedResults<ConsumerEntity>
    
    var mainConsumers: [ConsumerEntity] {
        allGeneratorConsumers.filter { consumer in
            return consumer.priorityType == ConsumerPriorityType.main.rawValue
        }
    }
    
    var secondaryConsumers: [ConsumerEntity] {
        allGeneratorConsumers.filter { consumer in
            return consumer.priorityType == ConsumerPriorityType.secondary.rawValue
        }
    }

    var mainConsumersTotalConsumption: Float {
        mainConsumers.map { $0.consumption * Float($0.quantity) }.reduce(0, +)
    }
    
    var secondaryConsumersTotalConsumption: Float {
        secondaryConsumers.map { $0.consumption * Float($0.quantity) }.reduce(0, +)
    }
    
    var totalConsumption: Float {
        return allGeneratorConsumers.map { $0.consumption * Float($0.quantity) }.reduce(0, +)
    }
    
    var leftCapacity: Float {
        myCapacity - totalConsumption
    }

    var body: some View {
        NavigationView {
            List {
                Section(content: {
                    ForEach(mainConsumers) { mainConsumerItem in
                        NavigationLink {
                            ConsumerView(consumer: mainConsumerItem)
                        } label: {
                            Text(mainConsumerItem.name)
                        }
                    }
                    .onDelete(perform: deleteItems)
//                    .onMove { mainConsumers.move(fromOffsets: $0, toOffset: $1) }
                    .swipeActions(edge: .leading) {
                        Button(action: {
                            // Define your action here
                            print("Swipe action triggered")
                        }) {
                            Label("Activate", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.green)
                    }
                }, header: {
                    Text("Main item\(mainConsumers.count > 1 ? "s" : "")")
                }, footer: {
                    Text("Total: \(String(format: "%.2f", mainConsumersTotalConsumption)) Watt")
                })
                
                Section(content: {
                    ForEach(secondaryConsumers) { secondaryConsumerItem in
                        NavigationLink {
                            ConsumerView(consumer: secondaryConsumerItem)
                        } label: {
                            Text(secondaryConsumerItem.name)
                        }
                    }
                    .onDelete(perform: deleteItems)
//                    .onMove { mainConsumers.move(fromOffsets: $0, toOffset: $1) }
                    .swipeActions(edge: .leading) {
                        Button(action: {
                            // Define your action here
                            print("Swipe action triggered")
                        }) {
                            Label("Activate", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.green)
                    }
                }, header: {
                    Text("Main item\(secondaryConsumers.count > 1 ? "s" : "")")
                }, footer: {
                    Text("Total: \(String(format: "%.2f", secondaryConsumersTotalConsumption)) Watt")
                })
                
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
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
//            let newItem = ConsumerEntity(context: viewContext)
//            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { allGeneratorConsumers[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
