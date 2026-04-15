//
//  ConsumerViewModel.swift
//  Electricity consumption calculator
//
//  ViewModel for consumer operations — owns business logic
//

import Foundation
import Observation
import os

@Observable
final class ConsumerViewModel {
    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "ConsumerViewModel")

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    func toggleActiveStatus(consumer: ConsumerEntity) {
        persistenceController.container.viewContext.perform {
            consumer.isActive.toggle()
            self.persistenceController.saveContext()
        }
    }

    func deleteConsumer(consumer: ConsumerEntity) {
        persistenceController.container.viewContext.perform {
            self.persistenceController.deleteItem(consumer: consumer)
        }
    }

    func moveItems(from source: IndexSet, to destination: Int,
                   in priorityTypeGroup: ConsumerPriorityType,
                   allConsumers: [ConsumerEntity]) {
        var revisedItemsFromGroup = allConsumers.filter { $0.priorityType == priorityTypeGroup.rawValue }
        revisedItemsFromGroup.move(fromOffsets: source, toOffset: destination)

        for reverseIndex in stride(from: revisedItemsFromGroup.count - 1, through: 0, by: -1) {
            revisedItemsFromGroup[reverseIndex].orderInGroup = Int16(reverseIndex)
        }

        persistenceController.container.viewContext.perform {
            self.persistenceController.saveContext()
        }
    }
}
