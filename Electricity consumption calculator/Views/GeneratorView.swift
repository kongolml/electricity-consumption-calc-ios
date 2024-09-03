//
//  GeneratorView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI
import CoreData
import GoogleSignIn
import GoogleSignInSwift

struct AddNewGeneratorConsumerState {
    var isAddingNewConsumer: Bool = false
    var consumerPriorityType: ConsumerPriorityType = .main
}

struct GeneratorView: View {
    let authMiddleWare = AuthMiddleware()
    let generatorMiddleware = GeneratorMiddleware()
    let keychain = KeychainToolbox()
    let syncManager = SyncManager.shared
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var persistenceController: PersistenceController

    @StateObject var generatorViewModel: GeneratorViewModel
    
    @State private var allGeneratorConsumers: [ConsumerEntity] = []
    @State private var generatorConsumersLoaded = false
    @State private var path = NavigationPath()
    @State private var addNewGeneratorConsumerState = AddNewGeneratorConsumerState()
    
    let generatorId: String

    init(generatorId: UUID) {
        self.generatorId = generatorId.uuidString
        
        let generatorViewModel = GeneratorViewModel(context: PersistenceController.shared.container.viewContext)
        generatorViewModel.loadGeneratorById(self.generatorId)
        _generatorViewModel = StateObject(wrappedValue: generatorViewModel)
    }
    
    var totalConsumption: Double {
        return generatorViewModel.consumers.filter { $0.isActive }.map { $0.consumption * Double($0.quantity) }.reduce(0, +)
    }
    
    var leftCapacity: Double {
        return generatorViewModel.capacity - totalConsumption
    }
    
    private func filteredItems(for category: ConsumerPriorityType) -> [ConsumerEntity] {
        return allGeneratorConsumers.filter { $0.priorityType == category.rawValue }
    }
    
    @ViewBuilder
    func consumerRow(for consumerItem: ConsumerEntity) -> some View {
        NavigationLink(value: ConsumerNavigationItem(consumerId: consumerItem.id, isNewConsumer: false)) {
            ConsumerListItemView(consumer: consumerItem)
        }
        .swipeActions(edge: .leading) {
            Button(action: {
                toggleItemActiveStatus(consumer: consumerItem)
            }) {
                consumerItem.isActive ? Label("Deactivate", systemImage: "bolt.slash") : Label("Activate", systemImage: "powercord")
            }
            .tint(consumerItem.isActive ? .red : .green)
        }
        .swipeActions(edge: .trailing) {
            Button(action: {
                deleteItem(consumer: consumerItem)
            }) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
    
    @ViewBuilder
    func consumerGroupSection(for group: ConsumerPriorityType, with consumers: [ConsumerEntity]) -> some View {
        Section(content: {
            ForEach(consumers, id: \.self) { consumerItem in
                consumerRow(for: consumerItem)
            }
            .onMove { indices, newOffset in
                moveItems(from: indices, to: newOffset, in: group)
            }
        }, header: {
            if consumers.count > 1 {
                Text("\(group.namePlural) consumers")
            } else {
                Text("\(group.name) consumer")
            }
        }, footer: {
            let consumersTotalConsumption: Double = consumers
                .filter { $0.isActive }
                .map { $0.consumption * Double($0.quantity) }
                .reduce(0, +)
            
            Text("Total: \(convertEnergyDoubleToNiceFormat(value: consumersTotalConsumption)) Watt")
        })
    }
    
    @ViewBuilder
    func generatorSummarySection(for generator: GeneratorEntity) -> some View {
        Section(content: {
            HStack {
                Text("Total capacity")
                Spacer()
                Text("\(convertEnergyDoubleToNiceFormat(value: generator.capacity)) Watt")
                    .foregroundColor(.gray)
            }
            HStack {
                Text("Total consumption")
                Spacer()
                Text("\(convertEnergyDoubleToNiceFormat(value: totalConsumption)) Watt")
                    .foregroundColor(.gray)
            }
            HStack {
                Text("Left capacity")
                Spacer()
                Text("\(convertEnergyDoubleToNiceFormat(value: leftCapacity)) Watt")
                    .foregroundColor(.gray)
            }
        }, header: {
            Text("Summary")
        })
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if let currentGenerator = generatorViewModel.currentGenerator {
                    List {
                        GoogleSignInButton(action: handleSignInButton)
                        Button("Sign out google") {
                            signOutGoogle()
                        }
                        
                        if allGeneratorConsumers.isEmpty {
                            Text("No consumers yet")
                        }
                        
                        if !allGeneratorConsumers.isEmpty {
                            ForEach(ConsumerPriorityType.allCases, id: \.self) { consumerPriorityType in
                                let consumersInGroup = filteredItems(for: consumerPriorityType)
                                
                                if !consumersInGroup.isEmpty {
                                    consumerGroupSection(for: consumerPriorityType, with: consumersInGroup)
                                }
                            }
                        }
                        
                        generatorSummarySection(for: currentGenerator)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            NavigationLink {
                                GeneratorDetailsView()
                            } label: {
                                Label("Edit generator", systemImage: "gear")
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            EditButton()
                        }
                        ToolbarItem {
                            Button(action: {
                                addNewConsumer(priority: .main)
                            }) {
                                Label("Add Item", systemImage: "plus")
                            }
                        }
                    }
                    .refreshable {
                        print("MANuaLLY refrresing GENERATOR CONSUEMRS")
                        generatorViewModel.fetchGenerator()
                        allGeneratorConsumers = generatorViewModel.consumers
                        print(allGeneratorConsumers)
                    }
                    .onAppear {
                        print("REFRESHING GENERATOR CONSUEMRS")
    //                    generatorViewModel.setupSubscriptions(consumerViewModel: consumerViewModel)
                        generatorViewModel.fetchGenerator()
                        allGeneratorConsumers = generatorViewModel.consumers
                        print(allGeneratorConsumers)
                    }
                    .navigationDestination(for: ConsumerNavigationItem.self) { navigationItem in
                        ConsumerView(consumerId: navigationItem.consumerId, isNewConsumer: navigationItem.isNewConsumer)
                    }
                } else {
                    ProgressView("Loading")
                }
            }
            .navigationTitle(generatorViewModel.name)
        }
        .sheet(isPresented: $addNewGeneratorConsumerState.isAddingNewConsumer, content: {
            if let currentGenerator = generatorViewModel.currentGenerator {
                let newConsumer = persistenceController.createLocalConsumer(for: currentGenerator)
                
                NavigationStack {
                    ConsumerView(consumer: newConsumer, isNewConsumer: true)
                        .onDisappear {
                            print("on disappear refresh from generatorview")
                            generatorViewModel.fetchGenerator()
                            allGeneratorConsumers = generatorViewModel.consumers
                            print(allGeneratorConsumers)
                        }
                        .navigationTitle("New consumer")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Cancel") {
                                    cancellAddingNewConsumer(consumer: newConsumer)
                                }
                            }
                        }
                }

            }
        })
        .environmentObject(generatorViewModel)
    }
    
    private func addNewConsumer(priority: ConsumerPriorityType) {
        addNewGeneratorConsumerState.isAddingNewConsumer = true
        addNewGeneratorConsumerState.consumerPriorityType = priority
    }
    
    private func cancellAddingNewConsumer(consumer: ConsumerEntity) {
        addNewGeneratorConsumerState.isAddingNewConsumer = false
        persistenceController.deleteConsumer(consumer: consumer)
    }

    private func addNewConsumer1(priority: ConsumerPriorityType) {
        viewContext.perform {
            if let currentGenerator = generatorViewModel.currentGenerator {
                let newItem = persistenceController.createLocalConsumer(for: currentGenerator)
//                let newItem = ConsumerEntity(context: viewContext)
                newItem.priorityType = priority.rawValue
                
                persistenceController.saveContext()
                
                DispatchQueue.main.async {
                    withAnimation {
//                        path.append(newItem)
                        path.append(ConsumerNavigationItem(consumerId: newItem.id, isNewConsumer: true))
                    }
                }
            }
        }
    }
    
    private func toggleItemActiveStatus(consumer: ConsumerEntity) {
        viewContext.perform {
            consumer.isActive.toggle()
            
            persistenceController.saveContext()
        }
    }
    
    private func deleteItem(consumer: ConsumerEntity) {
        withAnimation {
            generatorViewModel.deleteConsumer(consumer: consumer)
            
            allGeneratorConsumers = generatorViewModel.consumers
        }
    }
    
//    private func deleteItemsInBulk(offsets: IndexSet) {
//        viewContext.perform {
//            offsets.map { consumersList[$0] }.forEach { consumer in
//                viewContext.delete(consumer)
//            }
//            
//            persistenceController.saveContext()
//        }
//    }
    
    private func moveItems(from source: IndexSet, to destination: Int, in priorityTypeGroup: ConsumerPriorityType) {
        var revisedItemsFromGroup = allGeneratorConsumers.map { $0 }.filter { $0.priorityType == priorityTypeGroup.rawValue }
        revisedItemsFromGroup.move(fromOffsets: source, toOffset: destination)

        for reverseIndex in stride(from: revisedItemsFromGroup.count - 1, through: 0, by: -1) {
            revisedItemsFromGroup[reverseIndex].orderInGroup = Int16(reverseIndex)
        }

        viewContext.perform {
            persistenceController.saveContext()
        }
    }
    
    func handleSignInButton() {
      GIDSignIn.sharedInstance.signIn(
        withPresenting: getRootViewController()) { signInResult, error in
            guard error == nil else { return }
                guard let signInResult = signInResult else { return }

                signInResult.user.refreshTokensIfNeeded { user, error in
                    guard error == nil else { return }
                    guard let user = user else { return }

                    let idToken = user.idToken
                    // Send ID token to backend (example below).
                    if (idToken?.tokenString != nil) {
                        authorizeOnApiUsingGoogleToken(idToken: idToken!.tokenString)
                        let keychain = KeychainToolbox()
                        keychain.setGoogleIdToken(value: idToken!.tokenString)
                    }
                }
        }
//      )
        print("handleSignInButton handleSignInButton handleSignInButton handleSignInButton")
    }
    
    func authorizeOnApiUsingGoogleToken(idToken: String) {
        guard !idToken.isEmpty else {
            return
        }

        authMiddleWare.signInWithGoogleToken(idToken: idToken) { accesTokens, error  in
            print("here is response")
            
            if let error = error {
                debugPrint(error)
            } else if let accesTokens = accesTokens {
                keychain.setUserApiToken(newToken: accesTokens.accessToken)
                print(accesTokens.accessToken)
            }
        }
    }
    
    func signOutGoogle() {
        GIDSignIn.sharedInstance.signOut()
    }
}

extension View {
    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }

        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }
        

        return root
    }
}


#Preview {
    @Environment(\.managedObjectContext) var viewContext

    let dummyGenerator = GeneratorEntity.createMock(context: viewContext)

    return GeneratorView(generatorId: dummyGenerator.id).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
