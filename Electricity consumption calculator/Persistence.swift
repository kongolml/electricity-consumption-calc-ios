//
//  Persistence.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import CoreData

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for index in 0..<10 {
            let dummyConsumerEntity = ConsumerEntity.createMock(context: viewContext)
        }

        let dummyGeneratorEntity = GeneratorEntity.createMock(context: viewContext)

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Electricity_consumption_calculator")
        
//        TODO: optimize it?
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        } else {
            let description = NSPersistentStoreDescription()
            let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("Electricity_consumption_calculator.sqlite")
            description.url = storeURL
            description.shouldInferMappingModelAutomatically = true
            description.shouldMigrateStoreAutomatically = true
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            self.setDefaultValuesForNewAttributesForConsumers()
            self.setDefaultValuesForNewAttributesForGenerators()
            
            if let storeURL = self.container.persistentStoreCoordinator.persistentStores.first?.url {
                print("core data sqlite: \(storeURL)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    private func setDefaultValuesForNewAttributesForConsumers() {
        let context = container.viewContext
        let fetchRequestConsumers: NSFetchRequest<ConsumerEntity> = ConsumerEntity.fetchRequest()
        
        do {
            let consumers = try context.fetch(fetchRequestConsumers)
            let defaultGenerator = self.fetchOrCreateDefaultGeneratorEntity()

            for consumer in consumers {
                if consumer.updatedAt == nil {
                    consumer.updatedAt = Date() // Set a default value to current date
                }
                if consumer.generator == nil {
                    consumer.generator = defaultGenerator
                }
            }
            try context.save()
        } catch {
            print("Failed to set default values: \(error)")
        }
    }
    
    private func setDefaultValuesForNewAttributesForGenerators() {
        let context = container.viewContext
        let fetchRequestConsumers: NSFetchRequest<GeneratorEntity> = GeneratorEntity.fetchRequest()
        
        do {
            let generators = try context.fetch(fetchRequestConsumers)

            for generator in generators {
                if generator.updatedAt == nil {
                    generator.updatedAt = Date() // Set a default value to current date
                }
            }
            try context.save()
        } catch {
            print("Failed to set default values: \(error)")
        }
    }
    
    func getGeneratorConsumers(generator: GeneratorEntity) -> [ConsumerEntity] {
//        TODO: should it be fetched here all the time? this function is used in few places, overkill?
        let fetchRequest: NSFetchRequest<ConsumerEntity> = ConsumerEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "generator == %@", generator)
        
        do {
            let generatorConsumers = try container.viewContext.fetch(fetchRequest)
            
            return generatorConsumers
        } catch {
            debugPrint(error)
        }
        
//        TODO: do not return empty array
        return []
    }
    
    func fetchLocalGenerators() -> [GeneratorEntity] {
        let fetchRequest: NSFetchRequest<GeneratorEntity> = GeneratorEntity.fetchRequest()
        
        do {
            let results = try container.viewContext.fetch(fetchRequest)
            
            return results
        } catch {
            fatalError("Error fetching GeneratorEntity: \(error.localizedDescription)")
        }
    }
    
    func fetchOrCreateDefaultGeneratorEntity() -> GeneratorEntity {
        let fetchRequest: NSFetchRequest<GeneratorEntity> = GeneratorEntity.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)

        fetchRequest.sortDescriptors = [sortDescriptor]
        // Limit the fetch to only one result
        fetchRequest.fetchLimit = 1

        do {
            let results = try container.viewContext.fetch(fetchRequest)
            if let existingEntity = results.first {
                return existingEntity
            } else {
                let newEntity = GeneratorEntity(context: container.viewContext)
                // Set default values for newEntity here if needed
                return newEntity
            }
        } catch {
            fatalError("Error fetching GeneratorEntity: \(error.localizedDescription)")
        }
    }
    
    func fetchConsumersOrCreateDefaults() -> ConsumerEntity? {
        let fetchRequest: NSFetchRequest<ConsumerEntity> = ConsumerEntity.fetchRequest()

        do {
            let results = try container.viewContext.fetch(fetchRequest)
            if let existingConsumer = results.first {
                return existingConsumer
            } else {
                let newConsumerMain = ConsumerEntity.createMock(context: container.viewContext)
                // Set default values for newEntity here if needed
                newConsumerMain.priorityType = ConsumerPriorityType.main.rawValue
                newConsumerMain.quantity = 1
                newConsumerMain.name = NSLocalizedString("defaul_value_fridge", comment: "")
                newConsumerMain.isActive = true
                
                let newConsumerSecondary = ConsumerEntity.createMock(context: container.viewContext)
                newConsumerSecondary.priorityType = ConsumerPriorityType.secondary.rawValue
                newConsumerSecondary.name = NSLocalizedString("defaul_value_backlight", comment: "")
                newConsumerSecondary.isActive = true
                
                return nil
            }
        } catch {
            fatalError("Error fetching GeneratorEntity: \(error.localizedDescription)")
        }
    }
    
    func saveContext() {
        do {
            try container.viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("TODO: handle error in saveItem")
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func deleteItem(consumer: ConsumerEntity) {
        container.viewContext.delete(consumer)
        saveContext()
    }
    
    func createGeneratorEntity(with generatorFromServer: GeneratorFromServer, context: NSManagedObjectContext) {
        let newGenerator = GeneratorEntity(context: context)
        newGenerator.dbid = generatorFromServer.id
        newGenerator.name = generatorFromServer.name
        newGenerator.updatedAt = generatorFromServer.updatedAt
        // Set other properties
    }
    
    func updateGeneratorEntity(_ localGenerator: GeneratorEntity, with generatorFromServer: GeneratorFromServer) {
        localGenerator.dbid = generatorFromServer.id
        localGenerator.name = generatorFromServer.name
        localGenerator.capacity = generatorFromServer.capacity
        localGenerator.updatedAt = generatorFromServer.updatedAt
        
//        // Add consumer to generator's consumers set
//        let consumerEntities = localGenerator.mutableSetValue(forKey: "consumers")
//        let localConsumersDbIds = consumerEntities.compactMap { entity -> String? in
//            guard let consumerEntity = entity as? ConsumerEntity, let localDbid = consumerEntity.dbid else {
//                return nil
//            }
//
//            return localDbid
//        }
//
//        for consumerFromServer in generatorFromServer.consumers {
//            // TODO: check for perfrmance loop inside loop
//            for entity in consumerEntities {
//                if let localConsumer = entity as? ConsumerEntity {
//                    if localConsumersDbIds.contains(consumerFromServer.id) {
//                        // update local consumer if needed
//                        if let localConsumerWithThisServerId = consumerEntities.compactMap({ $0 as? ConsumerEntity }).first(where: { $0.dbid == consumerFromServer.id }) {
//                            updateConsumerEntity(localConsumerWithThisServerId, with: consumerFromServer)
//                        }
//                    } else {
//                        // create new local consumer for generator from server items
//                        let consumerEntity = createConsumerEntityFromServer(with: consumerFromServer)
//                        consumerEntities.add(consumerEntity)
//                    }
//                }
//            }
//        }
    }
    
    func createConsumerEntityFromServer(with consumerFromServer: ConsumerFromServer) -> ConsumerEntity {
        let consumerEntity = ConsumerEntity(context: container.viewContext)
        
//        TODO: removal handler idea?
//        if consumerFromServer.isDeleted {
//            return
//        }

        consumerEntity.dbid = consumerFromServer.id
        consumerEntity.name = consumerFromServer.name
        consumerEntity.consumption = consumerFromServer.consumption
        consumerEntity.isActive = consumerFromServer.isActive
        consumerEntity.priorityType = Int16(consumerFromServer.priorityType.rawValue)
        consumerEntity.quantity = consumerFromServer.quantity
        consumerEntity.orderInGroup = consumerFromServer.orderInGroup
        consumerEntity.updatedAt = consumerFromServer.updatedAt
        
        return consumerEntity
    }
    
//    func updateConsumerEntity(_ localConsumer: ConsumerEntity, with consumerFromServer: ConsumerFromServer) {
//        if localConsumer.updatedAt == consumerFromServer.updatedAt {
//            print("ok  local and external consumers have the same udpatedAt")
//            return
//        }
//        
//        if localConsumer.updatedAt < consumerFromServer.updatedAt {
//            localConsumer.dbid = consumerFromServer.id
//            localConsumer.name = consumerFromServer.name
//            localConsumer.consumption = consumerFromServer.consumption
//            localConsumer.isActive = consumerFromServer.isActive
//            localConsumer.orderInGroup = consumerFromServer.orderInGroup
//            
//            if let priorityType = PriorityType(rawValue: consumerFromServer.priorityType.rawValue) {
//                localConsumer.priorityType = Int16(priorityType.rawValue)
//            }
//            
//            localConsumer.quantity = consumerFromServer.quantity
//            localConsumer.updatedAt = consumerFromServer.updatedAt
//        } else if localConsumer.updatedAt > consumerFromServer.updatedAt {
//            // TODO: implement this !!!!
//            print(" NOT YET IMPLEMENTED IN updateConsumerEntity")
//        }
//    }
}
