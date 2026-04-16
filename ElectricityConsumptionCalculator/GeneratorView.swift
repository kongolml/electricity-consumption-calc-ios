//
//  GeneratorView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI
import CoreData

struct GeneratorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var persistenceController: PersistenceController

    @ObservedObject var generator: GeneratorEntity

    @FetchRequest private var allGeneratorConsumers: FetchedResults<ConsumerEntity>

    init(generator: GeneratorEntity) {
        self.generator = generator
        self._allGeneratorConsumers = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \ConsumerEntity.orderInGroup, ascending: true)],
            predicate: NSPredicate(format: "relationship == %@", generator),
            animation: .default
        )
    }

    var totalConsumption: Double {
        ConsumptionCalculator.totalConsumption(for: Array(allGeneratorConsumers))
    }

    var leftCapacity: Double {
        ConsumptionCalculator.remainingCapacity(generator: generator, consumers: Array(allGeneratorConsumers))
    }

    var loadPercentage: Double {
        ConsumptionCalculator.loadPercentage(generator: generator, consumers: Array(allGeneratorConsumers))
    }

    var loadStatus: LoadStatus {
        ConsumptionCalculator.loadStatus(percentage: loadPercentage)
    }

    private func filteredItems(for category: ConsumerPriorityType) -> [ConsumerEntity] {
        ConsumptionCalculator.groupedByPriority(consumers: Array(allGeneratorConsumers))[category] ?? []
    }

    var body: some View {
        NavigationStack {
            List {
                // Load Gauge Section
                Section {
                    LoadGaugeView(
                        loadPercentage: loadPercentage,
                        loadStatus: loadStatus,
                        totalConsumption: totalConsumption,
                        generatorCapacity: generator.capacity
                    )
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if allGeneratorConsumers.isEmpty {
                    Text("No consumers yet")
                }

                if !allGeneratorConsumers.isEmpty {
                    ForEach(ConsumerPriorityType.allCases, id: \.self) { filteredConsumersGroup in
                        let consumersInGroup = filteredItems(for: filteredConsumersGroup)

                        Section(content: {
                            ForEach(consumersInGroup, id: \.self) { consumerItem in
                                NavigationLink {
                                    ConsumerView(consumer: consumerItem)
                                } label: {
                                    ConsumerListItemView(consumer: consumerItem)
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
                            .onMove { indices, newOffset in
                                moveItems(from: indices, to: newOffset, in: filteredConsumersGroup)
                            }
                        }, header: {
                            if consumersInGroup.count > 1 {
                                Text("\(filteredConsumersGroup.namePlural) consumers")
                            } else {
                                Text("\(filteredConsumersGroup.name) consumer")
                            }
                        }, footer: {
                            let groupConsumption = ConsumptionCalculator.totalConsumption(for: consumersInGroup)
                            Text("Total: \(convertEnergyDoubleToNiceFormat(value: groupConsumption)) Watt")
                        })
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        GeneratorDetailsView(generator: generator)
                    } label: {
                        Label("Edit generator", systemImage: "gear")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Menu {
                        Button(action: {
                            addNewItem(priority: .critical)
                        }) {
                            Label("Critical device", systemImage: "bolt.circle")
                        }

                        Button(action: {
                            addNewItem(priority: .important)
                        }) {
                            Label("Important device", systemImage: "lightbulb.2")
                        }

                        Button(action: {
                            addNewItem(priority: .optional)
                        }) {
                            Label("Optional device", systemImage: "leaf")
                        }
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(generator.name)
        }
    }

    private func addNewItem(priority: ConsumerPriorityType) {
        viewContext.perform {
            withAnimation {
                let newItem = ConsumerEntity(context: viewContext)
                newItem.priorityType = priority.rawValue
                newItem.relationship = generator
                newItem.orderInGroup = Int16(allGeneratorConsumers.count)

                persistenceController.saveContext()
            }
        }
    }

    private func deleteItem(consumer: ConsumerEntity) {
        viewContext.perform {
            withAnimation {
                persistenceController.deleteItem(consumer: consumer)
            }
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int, in priorityTypeGroup: ConsumerPriorityType) {
        var revisedItemsFromGroup = allGeneratorConsumers.map { $0 }.filter { $0.priorityType == priorityTypeGroup.rawValue }
        revisedItemsFromGroup.move(fromOffsets: source, toOffset: destination)

        for reverseIndex in stride(from: revisedItemsFromGroup.count - 1, through: 0, by: -1) {
            revisedItemsFromGroup[reverseIndex].orderInGroup = Int16(reverseIndex)
        }

        viewContext.perform {
            persistenceController.saveContext()
        }
    }
}

#Preview {
    @Environment(\.managedObjectContext) var viewContext

    let dummyGenerator = GeneratorEntity.createMock(context: viewContext)

    return GeneratorView(generator: dummyGenerator).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
