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
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
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
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func fetchOrCreateDefaultGeneratorEntity() -> GeneratorEntity {
        let fetchRequest: NSFetchRequest<GeneratorEntity> = GeneratorEntity.fetchRequest()

        do {
            let results = try container.viewContext.fetch(fetchRequest)
            if let existingEntity = results.last {
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
        
//    TODO: refactor this, this was taked from internet as a proof-of-concept
    func saveGeneratorsToCoreData(generators: [GeneratorFromServer]) {
        let context = container.viewContext

        context.perform {
            for generator in generators {
                let fetchRequest: NSFetchRequest<GeneratorEntity> = GeneratorEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "dbid == %@", generator.id)

                if let existingGenerator = try? context.fetch(fetchRequest).first {
                    // Conflict resolution based on updatedAt
                    if generator.updatedAt > existingGenerator.updatedAt {
                        self.updateGeneratorEntity(existingGenerator, with: generator)
                    }
                } else {
                    // Insert new generator
                    self.createGeneratorEntity(with: generator, context: context)
                }
            }
            
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func createGeneratorEntity(with generatorFromServer: GeneratorFromServer, context: NSManagedObjectContext) {
        let newGenerator = GeneratorEntity(context: context)
        newGenerator.dbid = generatorFromServer.id
        newGenerator.name = generatorFromServer.name
        newGenerator.updatedAt = generatorFromServer.updatedAt
        // Set other properties
    }
    
    func updateGeneratorEntity(_ entity: GeneratorEntity, with generatorFromServer: GeneratorFromServer) {
        entity.name = generatorFromServer.name
        entity.updatedAt = generatorFromServer.updatedAt
        // Update other properties
    }
}
