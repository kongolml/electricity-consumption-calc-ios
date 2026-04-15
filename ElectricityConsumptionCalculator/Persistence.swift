//
//  Persistence.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import CoreData
import os

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
            guard let storeDescription = container.persistentStoreDescriptions.first else {
                fatalError("No persistent store descriptions found")
            }
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }

        var recoveryAttempted = false

        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                // Log the error with details
                AppLogger.persistence.error("Core Data failed to load persistent store: \(error), \(error.userInfo)")

                // Only attempt recovery once to prevent infinite loops
                guard !recoveryAttempted else {
                    AppLogger.persistence.error("Core Data recovery already attempted, skipping")
                    return
                }
                recoveryAttempted = true

                // Attempt recovery: backup and delete the corrupted store, then retry
                guard let self = self else { return }
                let storeURL = storeDescription.url
                let storeType = storeDescription.type

                if storeType == NSSQLiteStoreType, let url = storeURL {
                    let fileManager = FileManager.default
                    let walURL = url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + "-wal")
                    let shmURL = url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent + "-shm")

                    // Create backup before deletion to prevent data loss
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let backupDir = url.deletingLastPathComponent().appendingPathComponent("Backups")
                    let backupURL = backupDir.appendingPathComponent("\(url.lastPathComponent).backup-\(timestamp)")

                    do {
                        if !fileManager.fileExists(atPath: backupDir.path) {
                            try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
                        }
                        try fileManager.copyItem(at: url, to: backupURL)
                        AppLogger.persistence.info("Created Core Data backup at: \(backupURL.lastPathComponent)")
                    } catch {
                        AppLogger.persistence.error("Failed to create Core Data backup: \(error.localizedDescription)")
                    }

                    for fileURL in [url, walURL, shmURL] {
                        if fileManager.fileExists(atPath: fileURL.path) {
                            do {
                                try fileManager.removeItem(at: fileURL)
                                AppLogger.persistence.info("Removed corrupted Core Data file: \(fileURL.lastPathComponent)")
                            } catch {
                                AppLogger.persistence.error("Failed to remove Core Data file: \(error.localizedDescription)")
                            }
                        }
                    }

                    // Retry loading with a fresh store
                    self.container.loadPersistentStores { _, retryError in
                        if let retryError = retryError {
                            AppLogger.persistence.error("Core Data recovery also failed: \(retryError)")
                        } else {
                            AppLogger.persistence.info("Core Data store successfully recovered")
                        }
                    }
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func fetchOrCreateDefaultGeneratorEntity() -> GeneratorEntity? {
        let fetchRequest: NSFetchRequest<GeneratorEntity> = GeneratorEntity.fetchRequest()

        do {
            let results = try container.viewContext.fetch(fetchRequest)
            if let existingEntity = results.first {
                return existingEntity
            } else {
                let newEntity = GeneratorEntity(context: container.viewContext)
                // Set default values for newEntity here if needed
                try container.viewContext.save()
                return newEntity
            }
        } catch {
            AppLogger.persistence.error("Error fetching or creating GeneratorEntity: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchOrCreateDefaultConsumers() -> ConsumerEntity? {
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
                newConsumerMain.name = NSLocalizedString("default_value_fridge", comment: "")
                newConsumerMain.isActive = true

                let newConsumerSecondary = ConsumerEntity.createMock(context: container.viewContext)
                newConsumerSecondary.priorityType = ConsumerPriorityType.secondary.rawValue
                newConsumerSecondary.name = NSLocalizedString("default_value_backlight", comment: "")
                newConsumerSecondary.isActive = true

                try container.viewContext.save()
                return nil
            }
        } catch {
            AppLogger.persistence.error("Error fetching or creating consumers: \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveContext() {
        guard container.viewContext.hasChanges else { return }

        do {
            try container.viewContext.save()
        } catch {
            let nsError = error as NSError
            AppLogger.persistence.error("Error saving context: \(nsError), \(nsError.userInfo)")
            // Handle error appropriately - maybe show alert to user
        }
    }
    
    func deleteItem(consumer: ConsumerEntity) {
        container.viewContext.delete(consumer)
        saveContext()
    }
}

extension Logger {
    static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "Persistence")
    static let auth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "Auth")
}
