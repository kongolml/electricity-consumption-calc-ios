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
    
    private init() {}
    
    func pushLocalGeneratorToServer(localGenerator: GeneratorEntity, comletion: @escaping (GeneratorEntity) -> Void) {
        generatorMiddleware.addNewGenerator(newGenerator: localGenerator).receive(on: DispatchQueue.main).sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break // Handle finished if needed
            case .failure(let error):
                debugPrint(error.localizedDescription)
            }
        }, receiveValue: { createdGenerator in
            self.persistenceController.updateGeneratorEntity(localGenerator, with: createdGenerator)
            self.persistenceController.saveContext()
            
            comletion(localGenerator)
        })
        //.store(in: &cancellables)
    }
    
    func handleGeneratorsListFromServer(generatorsFromServer: [GeneratorFromServer], completion: ((GeneratorEntity) -> Void)? = nil) {
        if generatorsFromServer.isEmpty {
            let defaultGenerator = persistenceController.fetchOrCreateDefaultGeneratorEntity()

            pushLocalGeneratorToServer(localGenerator: defaultGenerator, comletion: { generator in
                completion?(generator)
            })
        } else {
//            TODO: what if local will have more that one !!!
            let localGenerators = persistenceController.fetchLocalGenerators()
            
            // Create a dictionary for quick lookup
            var generatorsFromServerDict = [String: GeneratorFromServer]()
            for generator in generatorsFromServer {
                generatorsFromServerDict[generator.id] = generator
            }
            
            // Iterate through Core Data objects
            for localGenerator in localGenerators {
                if let generatorDbId = localGenerator.dbid {
                    if let serverItem = generatorsFromServerDict[generatorDbId] {
                        syncLocalAndRemoteGenerator(generatorFromServer: serverItem, localGenerator: localGenerator, completion: { generator in
                            completion?(generator)
                        })
                    }
                } else {
                    // local generator, which was not saved to server
                    pushLocalGeneratorToServer(localGenerator: localGenerator, comletion: { generator in
                        completion?(generator)
                    })
                }
            }
        }
    }
    
    func syncLocalAndRemoteGenerator(generatorFromServer: GeneratorFromServer, localGenerator: GeneratorEntity, completion: ((GeneratorEntity) -> Void)? = nil) {
        if (generatorFromServer.updatedAt == localGenerator.updatedAt) {
            print("ok  local and external generators have the same udpatedAt")
            completion?(localGenerator)
            return
        }

        if generatorFromServer.updatedAt > localGenerator.updatedAt {
            // update local
            persistenceController.updateGeneratorEntity(localGenerator, with: generatorFromServer)
            persistenceController.saveContext()
            print("ok updated local generator ientity")
            
            completion?(localGenerator)
        } else if (generatorFromServer.updatedAt < localGenerator.updatedAt) {
            // update on server
            let patchPayload = GeneratorHttpPayload(from: localGenerator)
            generatorMiddleware.updateGenerator(generatorId: generatorFromServer.id, updatedGenerator: patchPayload, completion: { savedGenerator, error in
                if savedGenerator != nil {
                    print("OK UPDATED")

                    self.persistenceController.updateGeneratorEntity(localGenerator, with: savedGenerator!)
                    self.persistenceController.saveContext()
                    
                    completion?(localGenerator)
                }
            })
        }

        // this will update generator updatedAt on server, but here in memory we still have "previous" generator instance
        pushLocalGeneratorConsumers(localGenerator: localGenerator)
    }
    
    func pushLocalGeneratorConsumers(localGenerator: GeneratorEntity) {
        guard let generatorDbId = localGenerator.dbid else {
            return
        }
        
        if let consumersSet = localGenerator.consumers as? Set<ConsumerEntity> {
            let consumersWithoutDbid = consumersSet.filter { consumer in
                return consumer.dbid == nil || consumer.dbid?.isEmpty == true
            }
            
            if !consumersWithoutDbid.isEmpty, let generatorDbId = localGenerator.dbid {
//                pushLocalGeneratorConsumers(localGenerator: localGenerator)
                // TODO: make it in one batch, not in loop - !!!!!
                for consumer in consumersWithoutDbid {
                    consumerMiddleware.createGeneratorConsumer(for: generatorDbId, with: consumer, completion: { consumerFromServer, error in
                        if let consumerFromServer = consumerFromServer {
                            self.persistenceController.updateConsumerEntity(consumer, with: consumerFromServer)
                            self.persistenceController.saveContext()
                        }
                    })
                }
            }
        }
    }
    
    /**
     This will get local and remote items and sych them, after it will return list of most recent items: ConsumerEntity
     */
    func getGeneratorConsumers(generatorEntity: GeneratorEntity, completion: (([ConsumerEntity]) -> Void)? = nil) {
        var isServerDataMoreRecent = false
        
        let dispatchGroup = DispatchGroup()
        var generatorConsumersFromServer: [ConsumerFromServer] = []
        var localGeneratorConsumers: [ConsumerEntity] = []
        var combinedConsumers: [ConsumerEntity] = []

        // get data from server
        if let generatorDbId = generatorEntity.dbid {
            dispatchGroup.enter()
            generatorMiddleware.getGeneratorById(generatorId: generatorDbId, completion: { generatorFromServer, error in
                if let generatorFromServer = generatorFromServer {
                    isServerDataMoreRecent = generatorFromServer.updatedAt > generatorEntity.updatedAt
                }
                
                if let generatorFromServer = generatorFromServer, !generatorFromServer.consumers.isEmpty {
                    generatorConsumersFromServer = generatorFromServer.consumers
                }
                
                dispatchGroup.leave()
            })
        }
        
        // Enter the dispatch group for the local data fetch
        dispatchGroup.enter()
        // Perform the local data fetch
        DispatchQueue.global().async {
            localGeneratorConsumers = self.persistenceController.getGeneratorConsumers(generator: generatorEntity)
            combinedConsumers.append(contentsOf: localGeneratorConsumers)
            // Leave the dispatch group after the local data fetch is done
            dispatchGroup.leave()
        }
        
        // Notify when both tasks are finished
        dispatchGroup.notify(queue: .main) {
            // combine it, update, serve
            for consumer in generatorConsumersFromServer {
                let newConsumerEntity = self.persistenceController.createConsumerEntityFromServer(with: consumer)
                combinedConsumers.append(newConsumerEntity)
            }
            
            completion?(combinedConsumers)
        }
    }
    
    func fetchUserGenerators(completion: ((GeneratorEntity) -> Void)? = nil) {
//        TODO: move this logic away from here
        if (keychain.getUserApiToken() != nil) {
            generatorMiddleware.getUserGenerators(completion: { userGeneratorsFromServer, error  in
                guard let userGeneratorsFromServer = userGeneratorsFromServer else {
                    let defaultGenerator = self.loadDefaultGenerator()
                    completion?(defaultGenerator)
                    return
                }

                self.handleGeneratorsListFromServer(generatorsFromServer: userGeneratorsFromServer, completion: { generatorToUse in
                    completion?(generatorToUse)
                })
                
//                if (userGeneratorsFromServer.isEmpty) {
//                    loadDefaultGenerator()
//                } else {
//                    let firstGeneratorFromServer = userGeneratorsFromServer.first
//                    defaultGenerator = GeneratorEntity(context: persistenceController.container.viewContext)
//
//                    if let defaultGenerator = defaultGenerator, let firstGeneratorFromServer = firstGeneratorFromServer {
//                        persistenceController.updateGeneratorEntity(defaultGenerator, with: firstGeneratorFromServer)
//                        persistenceController.saveContext()
//                    }
//                }
                
                if (error != nil) {
                    let defaultGenerator = self.loadDefaultGenerator()
                    completion?(defaultGenerator)
                }
            })
        } else {
            let defaultGenerator = self.loadDefaultGenerator()
            completion?(defaultGenerator)
        }
    }
    
    private func loadDefaultGenerator() -> GeneratorEntity {
        let defaultGenerator = persistenceController.fetchOrCreateDefaultGeneratorEntity()
        persistenceController.fetchConsumersOrCreateDefaults()
        
        return defaultGenerator
    }
}
