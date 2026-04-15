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

    @State private var showAddDeviceSheet = false

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
                        currentConsumption: totalConsumption,
                        maxCapacity: generator.capacity
                    )
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                // Surge Warning Section
                if generator.peakCapacity > 0 {
                    Section {
                        SurgeWarningView(
                            generator: generator,
                            consumers: Array(allGeneratorConsumers)
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }

                // Fuel Runtime Section
                if generator.fuelTankCapacity > 0 {
                    Section {
                        FuelRuntimeView(
                            generator: generator,
                            consumers: Array(allGeneratorConsumers)
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
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
                                .swipeActions(edge: .leading) {
                                    Button(action: {
                                        toggleItemActiveStatus(consumer: consumerItem)
                                    }) {
                                        consumerItem.isActive ? Label("Deactivate", systemImage: "bolt.slash") : Label("Activate", systemImage: "powercord")
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

                Section(content: {
                    HStack {
                        Text("Total capacity")
                        Spacer()
                        Text("\(convertEnergyDoubleToNiceFormat(value: generator.capacity)) Watt")
                            .foregroundStyle(.gray)
                    }
                    HStack {
                        Text("Total consumption")
                        Spacer()
                        Text("\(convertEnergyDoubleToNiceFormat(value: totalConsumption)) Watt")
                            .foregroundStyle(.gray)
                    }
                    HStack {
                        Text("Left capacity")
                        Spacer()
                        Text("\(convertEnergyDoubleToNiceFormat(value: leftCapacity)) Watt")
                            .foregroundStyle(.gray)
                    }
                }, header: {
                    Text("Summary")
                })
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
                    Button(action: {
                        showAddDeviceSheet = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddDeviceSheet) {
                AddDeviceFlowView(generator: generator)
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
