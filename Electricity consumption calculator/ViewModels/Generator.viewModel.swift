//
//  Generator.viewModel.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 08.08.2024.
//

import Foundation
import Combine
import CoreData

class GeneratorViewModel: ObservableObject {
    @Published var currentGenerator: GeneratorEntity?
    private var context: NSManagedObjectContext
    private let persistenceController = PersistenceController.shared
    private var cancellables: Set<AnyCancellable> = []
    private let syncManager = SyncManager.shared
    private let generatorMiddleware = GeneratorMiddleware()
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func loadGeneratorById(_ id: String){
        syncManager.getGeneratorById(id, context: context)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Failed to load generator: \(error)")
                }
            }, receiveValue: { [weak self] generator in
                self?.currentGenerator = generator
            })
            .store(in: &cancellables)
    }
    
    private func getCurrentGenerator() {
        Publishers.Zip(getGeneratorsFromCoreData(), fetchUserGenerators())
            .flatMap { coreDataGenerators, serverGenerators in
                // The flatMap operator is used because `mergeLocalAndRemoteGenerators` returns a publisher
//                self.syncManager.handleGeneratorsListFromServer(generatorsFromServer: serverGenerators, completion: { generator in
//                    
//                })
                self.syncManager.mergeLocalAndRemoteGenerators(localGenerators: coreDataGenerators, remoteGenerators: serverGenerators)
//                return (coreDataGenerators, serverGenerators)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Failed to fetch items: \(error)")
                }
            }, receiveValue: { mergedGeneratorsList in
                print(mergedGeneratorsList)
//                guard let userGenerator = mergedGeneratorsList.first else {
//                    self.currentGenerator = userGenerator
//                    return
//                }
            })
            .store(in: &cancellables)
    }
    
    private func fetchUserGenerators() -> Future<[GeneratorFromServer], Error> {
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
    
    private func getGeneratorsFromCoreData() -> AnyPublisher<[GeneratorEntity], Error> {
        Future { promise in
            let localGenerators = self.persistenceController.fetchLocalGenerators()
            
            guard let firstDefaultGenerator = localGenerators.first else {
                let error = NSError(domain: "com.yourapp.GeneratorViewModel", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Errored in GeneratorViewModel:getGeneratorFromCoreData - no local generators found?"])
                promise(.failure(error))
                return
            }

            promise(.success([firstDefaultGenerator]))
        }
        .eraseToAnyPublisher()
    }
    
//    private func loadDefaultGenerator() -> GeneratorEntity {
//        let defaultGenerator = persistenceController.fetchOrCreateDefaultGeneratorEntity()
//        persistenceController.fetchConsumersOrCreateDefaults()
//        
//        return defaultGenerator
//    }
}
