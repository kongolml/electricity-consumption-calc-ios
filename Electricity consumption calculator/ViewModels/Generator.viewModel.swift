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
    
    @Published var capacity: Double = 0
    @Published var name: String = ""
    @Published var isLoading: Bool = true
    @Published var consumers: [ConsumerEntity] = [] {
        didSet {
            bindConsumers()
        }
    }

    private var cancellables: Set<AnyCancellable> = []

    private func bindConsumers() {
        // Cancel existing bindings
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // Rebind consumers array to observe each ConsumerEntity
        consumers.forEach { consumer in
            consumer.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }

    private var context: NSManagedObjectContext
    private let persistenceController = PersistenceController.shared
//    private var cancellables: Set<AnyCancellable> = []
    private let syncManager = SyncManager.shared
    private let generatorMiddleware = GeneratorMiddleware()
    
//    func setupSubscriptions(consumerViewModel: ConsumerViewModel) {
//        consumerViewModel.consumerUpdated
//            .sink { [weak self] updatedConsumer in
////                self?.refetchConsumers(updatedConsumer: updatedConsumer)
//                self?.updateConsumers()
//            }
//            .store(in: &cancellables)
//    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
        bindConsumers()
    }
    
    func loadGeneratorById(_ id: String){
        syncManager.getGeneratorById(id, context: context)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Failed to load generator: \(error)")
                }
            }, receiveValue: { [weak self] generator in
                if let generator = generator {
                    self?.setCurrentGenerator(from: generator)
                }
            })
            .store(in: &cancellables)
    }
    
    func fetchGenerator() {
        getCurrentGenerator()
    }
    
    func updateConsumers() {
        if let currentGenerator = currentGenerator {
            consumers = persistenceController.getGeneratorConsumers(generator: currentGenerator)
            print("ive set consumers in updateconsuemrs")
            print("start:-------------------")
            print(consumers)
            print("-------------------finish;")
        }
//        getGeneratorsFromCoreData()
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { completion in
//                if case let .failure(error) = completion {
//                    print("Failed to fetch items: \(error)")
//                }
//            }, receiveValue: { mergedGeneratorsList in
//                print(mergedGeneratorsList)
//                guard let userGenerator = mergedGeneratorsList.first else {
//                    return
//                }
//                self.setCurrentGenerator(from: userGenerator)
//            })
//            .store(in: &cancellables)
    }
    
    func deleteConsumer(consumer: ConsumerEntity) {
        if let currentGenerator = currentGenerator {
            guard let consumersSet = currentGenerator.consumers else {
                return
            }

            let consumersArray = consumersSet.compactMap { $0 as? ConsumerEntity }

            if let consumerToDelete = consumersArray.first(where: { $0.id == consumer.id }) {
                currentGenerator.removeFromConsumers(consumerToDelete)
            }
            
            persistenceController.deleteConsumer(consumer: consumer)

            setCurrentGenerator(from: currentGenerator)
        }
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
                guard let userGenerator = mergedGeneratorsList.first else {
                    return
                }
                self.setCurrentGenerator(from: userGenerator)
            })
            .store(in: &cancellables)
    }
    
    private func setCurrentGenerator(from generator: GeneratorEntity) {
        self.currentGenerator = generator
        self.name = generator.name
        self.capacity = generator.capacity
        
        guard let consumersSet = generator.consumers else {
            self.consumers = []
            return
        }
        
        let consumersArray = consumersSet.compactMap { $0 as? ConsumerEntity }
        // You can now use consumersArray, which is an array of ConsumerEntity objects
        self.consumers = consumersArray
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
            
//            TODO: this should not be here i think!!!
            self.setCurrentGenerator(from: firstDefaultGenerator)
            promise(.success([firstDefaultGenerator]))
        }
        .eraseToAnyPublisher()
    }
    
    func updateGenerator() {
        if let currentGenerator = currentGenerator {
            context.perform {
                currentGenerator.name = self.name
                currentGenerator.capacity = self.capacity

                currentGenerator.updatedAt = Date()
                print("set properties")
                
                self.setCurrentGenerator(from: currentGenerator)
                print("set current")
                
                self.syncManager.updateRemoteGenerator(localGenerator: currentGenerator)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            debugPrint("Failed to updateGenerator in GeneratorViewModel: \(error.localizedDescription)")
//                            promise(.failure(error))
                        case .finished:
                            break
                        }
                    }, receiveValue: { updatedGenerator in
//                        guard let firstUserGenerator = generatorsFromServer.first else {
//                            promise(.success([]))
//                            return
//                        }
//                        
//                        let arrayOfRemoteGenerators = [firstUserGenerator]
//                        promise(.success(arrayOfRemoteGenerators))
                    })
                    .store(in: &self.cancellables)
                print("will save context")
                self.persistenceController.saveContext()
            }
        }
    }
}
