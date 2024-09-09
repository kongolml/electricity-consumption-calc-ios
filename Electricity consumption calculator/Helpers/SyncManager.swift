//
//  SyncManager.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 28.07.2024.
//

import Foundation
import Combine
import CoreData

class SyncManager {
    static let shared = SyncManager()
    
    private let keychain = KeychainToolbox()
    private let generatorMiddleware = GeneratorMiddleware()
    private let consumerMiddleware = ConsumerMiddleware()
    private let persistenceController = PersistenceController.shared
    private var cancellables: Set<AnyCancellable> = []
    
    private init() {}
    
    func pushLocalGeneratorToServer(localGenerator: GeneratorEntity/*, comletion: @escaping (GeneratorEntity) -> Void*/) -> Future<GeneratorEntity, Error> {
        return Future { promise in
            self.generatorMiddleware.addNewGenerator(newGenerator: localGenerator)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break // Handle finished if needed
                    case .failure(let error):
                        debugPrint(error.localizedDescription)
                        promise(.failure(error))
                    }
                }, receiveValue: { createdGenerator in
                    self.persistenceController.updateGeneratorEntity(localGenerator, with: createdGenerator)
                    self.persistenceController.saveContext()
                    
                    promise(.success(localGenerator))
                })
                //.store(in: &cancellables)
        }
    }
    
    func handleGeneratorsListFromServer(generatorsFromServer: [GeneratorFromServer]) -> Future<[GeneratorEntity], Error> {
        return Future { promise in
            if generatorsFromServer.isEmpty {
                let defaultGenerator = self.persistenceController.fetchOrCreateDefaultGeneratorEntity()

                self.pushLocalGeneratorToServer(localGenerator: defaultGenerator)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break // Handle finished if needed
                        case .failure(let error):
                            debugPrint(error.localizedDescription)
                            promise(.failure(error))
                        }
                    }, receiveValue: { uploadedGenerator in
                        promise(.success([uploadedGenerator]))
                    })
            } else {
    //            TODO: what if local will have more that one !!!
                let localGenerators = self.persistenceController.fetchLocalGenerators()
                self.mergeLocalAndRemoteGenerators(localGenerators: localGenerators, remoteGenerators: generatorsFromServer)
            }
        }
            
            
            
//        if generatorsFromServer.isEmpty {
//            let defaultGenerator = persistenceController.fetchOrCreateDefaultGeneratorEntity()
//
//            pushLocalGeneratorToServer(localGenerator: defaultGenerator, comletion: { generator in
//                completion?(generator)
//            })
//        } else {
////            TODO: what if local will have more that one !!!
//            let localGenerators = persistenceController.fetchLocalGenerators()
//            
//            mergeLocalAndRemoteGenerators(localGenerators: localGenerators, remoteGenerators: generatorsFromServer)
            
//            // Create a dictionary for quick lookup
//            var generatorsFromServerDict = [String: GeneratorFromServer]()
//            for generator in generatorsFromServer {
//                generatorsFromServerDict[generator.id] = generator
//            }
//            
//            // Iterate through Core Data objects
//            for localGenerator in localGenerators {
//                if let generatorDbId = localGenerator.dbid {
//                    if let serverItem = generatorsFromServerDict[generatorDbId] {
//                        syncLocalAndRemoteGenerator(generatorFromServer: serverItem, localGenerator: localGenerator, completion: { generator in
//                            completion?(generator)
//                        })
//                    }
//                } else {
//                    // local generator, which was not saved to server
//                    pushLocalGeneratorToServer(localGenerator: localGenerator, comletion: { generator in
//                        completion?(generator)
//                    })
//                }
//            }
        
    }
    
    /**
     Will sync local and remote generators and return local generators list with latest changes
     */
    func mergeLocalAndRemoteGenerators(localGenerators: [GeneratorEntity], remoteGenerators: [GeneratorFromServer]) -> AnyPublisher<[GeneratorEntity], Error> {
//        return Future<Void, Never> { promise in
            // Create a dictionary for quick lookup
            var generatorsFromServerDict = [String: GeneratorFromServer]()
            for generator in remoteGenerators {
                generatorsFromServerDict[generator.id] = generator
            }
            var syncRequests: [AnyPublisher<GeneratorEntity, Error>] = []
            
            // Iterate through Core Data objects
            for localGenerator in localGenerators {
                if let generatorDbId = localGenerator.dbid {
                    if let serverItem = generatorsFromServerDict[generatorDbId] {
                        let requestToSyncGeneratos = self.syncLocalAndRemoteGenerator(generatorFromServer: serverItem, localGenerator: localGenerator).eraseToAnyPublisher()
                        syncRequests.append(requestToSyncGeneratos)
                    }
                } else {
                    // local generator, which was not saved to server
//                    pushLocalGeneratorToServer(localGenerator: localGenerator)
                    let requestToSyncGeneratos = self.pushLocalGeneratorToServer(localGenerator: localGenerator).eraseToAnyPublisher()
                    syncRequests.append(requestToSyncGeneratos)
                }
            }
            
            // Using zip to combine all requests
//            return Publishers.ZipMany(syncRequests)
//                .eraseToAnyPublisher()
        return zipPublishers(syncRequests)
            .map { syncedGenerators in
                // After syncing, replace the corresponding local generators with the synced ones
                var updatedLocalGenerators = localGenerators
                for syncedGenerator in syncedGenerators {
                    if let index = updatedLocalGenerators.firstIndex(where: { $0.dbid == syncedGenerator.dbid }) {
                        updatedLocalGenerators[index] = syncedGenerator
                    } else {
                        updatedLocalGenerators.append(syncedGenerator)
                    }
                }
                return updatedLocalGenerators
            }
            .eraseToAnyPublisher()
//        }
    }
            
    // Helper function to zip an array of publishers into a single publisher
    private func zipPublishers<T>(_ publishers: [AnyPublisher<T, Error>]) -> AnyPublisher<[T], Error> {
        guard let first = publishers.first else {
            // If there are no publishers, return an empty array
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return publishers.dropFirst().reduce(first.map { [$0] }.eraseToAnyPublisher()) { combined, next in
            combined
                .zip(next) { (results, nextResult) in
                    return results + [nextResult]
                }
                .eraseToAnyPublisher()
        }
    }
    
    func syncLocalAndRemoteGenerator(generatorFromServer: GeneratorFromServer, localGenerator: GeneratorEntity) -> Future<GeneratorEntity, Error> {
        return Future<GeneratorEntity, Error> { promise in
            if (generatorFromServer.updatedAt == localGenerator.updatedAt) {
                print("ok  local and external generators have the same udpatedAt")
                self.syncGeneratorConsumers(localGenerator: localGenerator, generatorFromServer: generatorFromServer)
                promise(.success(localGenerator))
                return
            }

            if generatorFromServer.updatedAt > localGenerator.updatedAt {
                // update local
                self.persistenceController.updateGeneratorEntity(localGenerator, with: generatorFromServer)
                self.persistenceController.saveContext()
                print("ok updated local generator ientity")
                
                promise(.success(localGenerator))
            } else if (generatorFromServer.updatedAt < localGenerator.updatedAt) {
                // update on server
                let patchPayload = GeneratorHttpPayload(from: localGenerator)
                self.generatorMiddleware.updateGenerator(generatorId: generatorFromServer.id, updatedGenerator: patchPayload, completion: { savedGenerator, error in
                    if savedGenerator != nil {
                        print("OK UPDATED")

                        self.persistenceController.updateGeneratorEntity(localGenerator, with: savedGenerator!)
                        self.persistenceController.saveContext()
                        
                        promise(.success(localGenerator))
                    }
                })
            }
            
            self.syncGeneratorConsumers(localGenerator: localGenerator, generatorFromServer: generatorFromServer)
        }
    }
    
    func syncGeneratorConsumers(localGenerator: GeneratorEntity, generatorFromServer: GeneratorFromServer) {
        // TODO: this will update generator updatedAt on server, but here in memory we still have "previous" generator instance
        pushLocalGeneratorConsumers(localGenerator: localGenerator)
        
        // Add consumer to generator's consumers set
        let consumerEntities = persistenceController.getGeneratorConsumers(generator: localGenerator)
        let localConsumersDbIds = consumerEntities.compactMap { consumer in
            return consumer.dbid
        }

        for consumerFromServer in generatorFromServer.consumers {
            // TODO: check for perfrmance loop inside loop
            // TODO: improve, its being called multiple times !!!
            if localConsumersDbIds.contains(consumerFromServer.id) {
                // update from server
                if let localConsumerWithThisServerId = consumerEntities.first(where: { $0.dbid == consumerFromServer.id }) {
                    // update local consumer if needed
                    updateConsumerEntity(localConsumerWithThisServerId, with: consumerFromServer, generatorDbId: generatorFromServer.id)
                }
            } else {
                // pull create from server
                // create new local consumer for generator from server items
                let consumerEntity = self.persistenceController.createConsumerEntityFromServer(with: consumerFromServer, for: localGenerator)
                persistenceController.saveContext()
            }
        }
        
        self.persistenceController.saveContext()
    }
    
    
    func updateConsumerEntity(_ localConsumer: ConsumerEntity, with consumerFromServer: ConsumerFromServer? = nil, generatorDbId: String) {
        guard let remoteConsumer = consumerFromServer else {
            consumerMiddleware.updateGeneratorConsumer(generatorDbId: generatorDbId, with: localConsumer, completion: { updatedConsumer, error  in
                // TODO: implement this !!!!
                print(" !!!!! i've pushed local consumer")
                print(" NOT YET IMPLEMENTED IN updateConsumerEntity")
            })
            return
        }

        if localConsumer.updatedAt == remoteConsumer.updatedAt {
            print("ok  local and external consumers have the same udpatedAt")
            return
        }
        
        if localConsumer.updatedAt < remoteConsumer.updatedAt {
            localConsumer.dbid = remoteConsumer.id
            localConsumer.name = remoteConsumer.name
            localConsumer.consumption = remoteConsumer.consumption
            localConsumer.isActive = remoteConsumer.isActive
            localConsumer.orderInGroup = remoteConsumer.orderInGroup
            
            if let priorityType = ConsumerPriorityType(rawValue: remoteConsumer.priorityType.rawValue) {
                localConsumer.priorityType = Int16(priorityType.rawValue)
            }
            
            localConsumer.quantity = remoteConsumer.quantity
            localConsumer.updatedAt = remoteConsumer.updatedAt
            
            return
        }
        
        if localConsumer.updatedAt > remoteConsumer.updatedAt {
            consumerMiddleware.updateGeneratorConsumer(generatorDbId: generatorDbId, with: localConsumer, completion: { updatedConsumer, error  in
                // TODO: implement this !!!!
                print(" NOT YET IMPLEMENTED IN updateConsumerEntity")
            })
            
            return
        }
    }
    
    func pushLocalGeneratorConsumers(localGenerator: GeneratorEntity) {
        guard let generatorDbId = localGenerator.dbid else {
            return
        }
        
        if let consumersSet = localGenerator.consumers as? Set<ConsumerEntity> {
            let consumersWithoutDbid = consumersSet.filter { consumer in
                return consumer.dbid == nil || consumer.dbid?.isEmpty == true
            }
            
            if !consumersWithoutDbid.isEmpty {
//                pushLocalGeneratorConsumers(localGenerator: localGenerator)
                // TODO: make it in one batch, not in loop - !!!!!
                for consumer in consumersWithoutDbid {
                    consumerMiddleware.createGeneratorConsumer(for: generatorDbId, with: consumer, completion: { consumerFromServer, error in
                        if let consumerFromServer = consumerFromServer {
                            self.updateConsumerEntity(consumer, with: consumerFromServer, generatorDbId: generatorDbId)
                            self.persistenceController.saveContext()
                        }
                    })
                }
            }
        }
    }
    
    func getGeneratorToUse(completion: ((GeneratorEntity) -> Void)? = nil) {
        if keychain.getUserApiToken() == nil {
            self.getGeneratorsFromCoreData()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Failed to fetch items: \(error)")
                    }
                }, receiveValue: { generatorsFromCoreData in
                    guard let defaultLocalGenerator = generatorsFromCoreData.first else {
//                        self.currentGenerator = userGenerator
                        return
                    }
                    completion?(defaultLocalGenerator)
                })
                .store(in: &cancellables)
        } else {
            Publishers.Zip(getGeneratorsFromCoreData(), fetchUserGenerators())
                .flatMap { coreDataGenerators, serverGenerators in
                    // The flatMap operator is used because `mergeLocalAndRemoteGenerators` returns a publisher
                    self.mergeLocalAndRemoteGenerators(localGenerators: coreDataGenerators, remoteGenerators: serverGenerators)
                }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion2 in
                    if case let .failure(error) = completion2 {
                        print("Failed to fetch items: \(error)")
                        
                        self.getGeneratorsFromCoreData()
                            .receive(on: DispatchQueue.main)
                            .sink(receiveCompletion: { completion in
                                if case let .failure(error) = completion {
                                    print("Failed to fetch items: \(error)")
                                }
                            }, receiveValue: { generatorsFromCoreData in
                                guard let defaultLocalGenerator = generatorsFromCoreData.first else {
            //                        self.currentGenerator = userGenerator
                                    return
                                }
                                completion?(defaultLocalGenerator)
                            })
                            .store(in: &self.cancellables)
                    }
                }, receiveValue: { mergedGeneratorsList in
                    print(mergedGeneratorsList)
                    guard let userGeneratorToUse = mergedGeneratorsList.first else {
                        return
                    }
                    
                    completion?(userGeneratorToUse)
                })
                .store(in: &cancellables)
        }
    }
    
    func getGeneratorsFromCoreData() -> AnyPublisher<[GeneratorEntity], Error> {
        Future { promise in
            let localGenerators = self.persistenceController.fetchLocalGenerators()
            
            guard let firstDefaultGenerator = localGenerators.first else {
                let error = NSError(domain: "com.yourapp.syncManager.swift", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Errored in syncManager:getGeneratorsFromCoreData - no local generators found?"])
                promise(.failure(error))
                return
            }

            promise(.success([firstDefaultGenerator]))
        }
        .eraseToAnyPublisher()
    }
    
    func fetchUserGenerators() -> Future<[GeneratorFromServer], Error> {
        return Future { promise in
            self.generatorMiddleware.getUserGenerators()
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        debugPrint("Failed to load generators in GeneratorViewModel: \(error.localizedDescription)")
                        promise(.failure(error))
                    case .finished:
                        break
                    }
                }, receiveValue: { generatorsFromServer in
                    guard let firstUserGenerator = generatorsFromServer.first else {
                        promise(.success([]))
                        return
                    }
                    
                    let arrayOfRemoteGenerators = [firstUserGenerator]
                    promise(.success(arrayOfRemoteGenerators))
                })
                .store(in: &self.cancellables)
        }
    }
    
    func getGeneratorById(_ id: String, context: NSManagedObjectContext) -> AnyPublisher<GeneratorEntity?, Error> {
        return Future<GeneratorEntity?, Error> { promise in
            let fetchRequest: NSFetchRequest<GeneratorEntity> = GeneratorEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1
            
            // Prefetch the related consumers to avoid faults
            fetchRequest.relationshipKeyPathsForPrefetching = ["consumers"]

            do {
                let generators = try context.fetch(fetchRequest)
                if let generator = generators.first {
                    promise(.success(generator))
                } else {
                    // If not found, you might want to fetch from the server and update Core Data
                    // Or return nil if you handle the absence in the view
                    promise(.success(nil))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getConsumerById(_ id: String, context: NSManagedObjectContext) -> AnyPublisher<ConsumerEntity?, Error> {
        return Future<ConsumerEntity?, Error> { promise in
            let fetchRequest: NSFetchRequest<ConsumerEntity> = ConsumerEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1

            do {
                let consumers = try context.fetch(fetchRequest)
                if let consumer = consumers.first {
                    promise(.success(consumer))
                } else {
                    // If not found, you might want to fetch from the server and update Core Data
                    // Or return nil if you handle the absence in the view
                    promise(.success(nil))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchGeneratorConsumers(generator: GeneratorEntity) -> [ConsumerEntity] {
        return persistenceController.getGeneratorConsumers(generator: generator)
    }
    
    func updateRemoteGenerator(localGenerator: GeneratorEntity) -> Future<GeneratorFromServer, Error> {
        return Future { promise in
            let patchPayload = GeneratorHttpPayload(from: localGenerator)
            self.generatorMiddleware.updateGenerator(generatorId: localGenerator.id.uuidString, updatedGenerator: patchPayload, completion: { updatedGenerator, error in
                if let updatedGenerator = updatedGenerator {
                    promise(.success(updatedGenerator))
                }
                
                if let error = error {
                    promise(.failure(error))
                }
            })
        }
    }
}
