//
//  SyncManager.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 28.07.2024.
//

import Foundation
import Combine

class SyncManager {
    static let shared = SyncManager()
    
    private let generatorMiddleware = GeneratorMiddleware()
    private let consumerMiddleware = ConsumerMiddleware()
    private let persistenceController = PersistenceController.shared
    
    private init() {}
    
//    func syncGenerators(completion: @escaping (Result<Void, Error>) -> Void) {
//        networkManager.fetchGenerator { [weak self] result in
//            switch result {
//            case .success(let generator):
//                self?.persistenceController.saveGenerator(generatorData: generator)
//                completion(.success(()))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
    
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
    
    func pushGeneratorConsumersToServer() {
        
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
    
    func test() {
//        check list of generator consumers from server
//        
    }
}
