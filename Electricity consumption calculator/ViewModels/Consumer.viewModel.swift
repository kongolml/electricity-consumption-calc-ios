//
//  Consumer.viewModel.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 12.08.2024.
//

import Foundation
import Combine
import CoreData

class ConsumerViewModel: ObservableObject {
    private var currentConsumer: ConsumerEntity?
    
    @Published var consumption: Double = 0
    @Published var isActive: Bool = false
    @Published var name: String = ""
    @Published var priorityType: Int16 = 1
    @Published var quantity: Int16 = 0
    @Published var dbid: String?
    @Published var orderInGroup: Int16 = 0
    
    @Published var currentConsumerIsSet: Bool = false
    
    private var context: NSManagedObjectContext
    private let persistenceController = PersistenceController.shared
    private var cancellables: Set<AnyCancellable> = []
    private let syncManager = SyncManager.shared
    private let consumerMiddleware = ConsumerMiddleware()
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchConsumerById(_ id: String){
        syncManager.getConsumerById(id, context: context)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Failed to load consumer: \(error)")
                }
            }, receiveValue: { [weak self] receivedConsumer in
                if let consumer = receivedConsumer {
                    self?.setCurrentConsumer(consumer: consumer)
                }
            })
            .store(in: &cancellables)
    }
    
    func deleteConsumer() {
        print("TODO i should delete consumers")
        if let currentConsumer = currentConsumer {
            context.perform {
                self.persistenceController.deleteConsumer(consumer: currentConsumer)
            }
        }
        consumerMiddleware.deleteGeneratorConsumer()
    }
    
    func updateConsumer() {
        if let currentConsumer = currentConsumer {
            context.perform {
                currentConsumer.name = self.name
                currentConsumer.isActive = self.isActive
                currentConsumer.priorityType = self.priorityType
                currentConsumer.quantity = self.quantity
                currentConsumer.consumption = self.consumption
                currentConsumer.orderInGroup = self.orderInGroup

                currentConsumer.updatedAt = Date()
                
                self.syncManager.updateConsumerEntity(currentConsumer, generatorDbId: currentConsumer.id.uuidString)
                self.persistenceController.saveContext()
            }
        }
    }
    
    func setCurrentConsumer(consumer: ConsumerEntity) {
        self.currentConsumer = consumer
        
        self.name = consumer.name
        self.consumption = consumer.consumption
        self.isActive = consumer.isActive
        self.priorityType = consumer.priorityType
        self.quantity = consumer.quantity
        self.dbid = consumer.dbid
        self.orderInGroup = consumer.orderInGroup

        self.currentConsumerIsSet = true
    }
    
//    func setEmptyConsumer(for consumer: ConsumerEntity) -> ConsumerEntity {
//        return persistenceController.createLocalConsumer(for: generator)
//    }
    
//    func createEmptyConsumer() {
//        let newItem = persistenceController.createLocalConsumer(for: currentGenerator)
//    }
}
