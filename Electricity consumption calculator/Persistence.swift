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
        
        let dummyGeneratorEntity = GeneratorEntity.createMock(context: viewContext)
        for index in 0..<10 {
            let dummyConsumerEntity = ConsumerEntity.createMock(context: viewContext, for: dummyGeneratorEntity)
        }

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
//        TODO: REMOVE THIS, ITS ONLY FOR DEBUGGING/DEVELOMENT
//        container.viewContext.refreshAllObjects()
        
//        TODO: should it be fetched here all the time? this function is used in few places, overkill?
        let fetchRequest: NSFetchRequest<ConsumerEntity> = ConsumerEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "generator == %@", generator)
        fetchRequest.relationshipKeyPathsForPrefetching = ["consumers"]
        
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
                let defaultGenerator = self.fetchOrCreateDefaultGeneratorEntity()
                let newConsumerMain = ConsumerEntity.createMock(context: container.viewContext, for: defaultGenerator)
                // Set default values for newEntity here if needed
                newConsumerMain.priorityType = ConsumerPriorityType.main.rawValue
                newConsumerMain.quantity = 1
                newConsumerMain.name = NSLocalizedString("defaul_value_fridge", comment: "")
                newConsumerMain.isActive = true
                
                let newConsumerSecondary = ConsumerEntity.createMock(context: container.viewContext, for: defaultGenerator)
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
    
    func createGeneratorEntity(with generatorFromServer: GeneratorFromServer) {
        let newGenerator = GeneratorEntity(context: container.viewContext)
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
    }
    
    func createConsumerEntityFromServer(with consumerFromServer: ConsumerFromServer, for generator: GeneratorEntity) -> ConsumerEntity {
        let consumerEntity = createLocalConsumer(for: generator)
        
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
        // TODO: add generator !!! ??
        consumerEntity.generator = generator
        
        return consumerEntity
    }
    
    func createLocalConsumer(for generator: GeneratorEntity) -> ConsumerEntity {
        let consumerEntity = ConsumerEntity(context: container.viewContext)
        consumerEntity.generator = generator
        
        return consumerEntity
    }
}
