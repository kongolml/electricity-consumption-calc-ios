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

//        generatorMiddleware.addNewGenerator(newGenerator: localGenerator, completion: { createdGenerator, error in
//            guard let createdGenerator = createdGenerator else {
//                return
//            }
//            
//            self.persistenceController.updateGeneratorEntity(localGenerator, with: createdGenerator)
//            
//            self.persistenceController.saveContext()
//        })
    }
    
    func handleGeneratorsListFromServer(generatorsFromServer: [GeneratorFromServer], completion: ((GeneratorEntity) -> Void)? = nil) {
        if generatorsFromServer.isEmpty {
            let defaultGenerator = persistenceController.fetchOrCreateDefaultGeneratorEntity()

            pushLocalGeneratorToServer(localGenerator: defaultGenerator, comletion: { generator in
                completion?(generator)
            })
        } else {
            let localGenerators = persistenceController.fetchLocalGenerators()
            
            // Create a dictionary for quick lookup
            var generatorsFromServerDict = [String: GeneratorFromServer]()
            for generator in generatorsFromServer {
                generatorsFromServerDict[generator.id] = generator
            }
            
            // Iterate through Core Data objects
            for localGenerator in localGenerators {
                if localGenerator.dbid != nil {
                    if let serverItem = generatorsFromServerDict[localGenerator.dbid!] {
                        syncLocalAndRemoteGenerator(generatorFromServer: serverItem, localGenerator: localGenerator, completion: { generator in
                            completion?(generator)
                        })
                    }
                } else {
                    // local generator, which was not saved to server
//                    pushLocalGeneratorToServer(localGenerator: localGenerator, comletion: { generator in
//                        completion?(generator)
//                    })
                }
            }
        }
    }
    
    func syncLocalAndRemoteGenerator(generatorFromServer: GeneratorFromServer, localGenerator: GeneratorEntity, completion: ((GeneratorEntity) -> Void)? = nil) {
        if let consumersSet = localGenerator.consumers as? Set<ConsumerEntity> {
            // Convert Set<ConsumerEntity> to Array<ConsumerEntity>
            let consumersArray = Array(consumersSet)

            let consumersWithoutDbid = consumersArray.filter { consumer in
                return consumer.dbid == nil
            }
            
            guard let generatorDbId = localGenerator.dbid else {
                return
            }
            
            if !consumersWithoutDbid.isEmpty {
                pushLocalGeneratorConsumers(generatorDbId: generatorDbId, localGeneratorConsumers: consumersWithoutDbid)
            }
        }

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
            // TODO: PASS CONSUMERS!!!!!!
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
    }
    
    func pushLocalGeneratorConsumers(generatorDbId: String, localGeneratorConsumers: [ConsumerEntity]) {
        for consumer in localGeneratorConsumers {
            consumerMiddleware.createGeneratorConsumer(for: generatorDbId, with: consumer, completion: { consumerFromServer, error in
                print("pushLocalGeneratorConsumers made a callback and its not handlede!!!")
            })
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
    
    /**
     Will update decide which generator is more recent (local or from server) and synch them
     */
    func syncLocalGeneratorWithRemote(localGenerator: GeneratorEntity, completion: ((GeneratorEntity) -> Void)? = nil) {
        guard let dbId = localGenerator.dbid else {
            return
        }

        generatorMiddleware.getGeneratorById(generatorId: dbId, completion: { generatorFromServer, error in
            if let generatorFromServer = generatorFromServer {
                self.syncLocalAndRemoteGenerator(generatorFromServer: generatorFromServer, localGenerator: localGenerator)
            }
            
            if let generatorFromServer = generatorFromServer, generatorFromServer.updatedAt > localGenerator.updatedAt {
                self.persistenceController.updateGeneratorEntity(localGenerator, with: generatorFromServer)
                self.persistenceController.saveContext()
            }
            
            completion?(localGenerator)
            
            // TODO: handle error here, its important
            if error != nil {
                
            }
        })
    }
}
