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
    
//    @State private var consumersSections: [ConsumerPriorityType: [ConsumerEntity]] = [:]
    
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
    
    var consumersSections: [ConsumerPriorityType: [ConsumerEntity]] {
        Dictionary(grouping: generatorViewModel.consumers, by: { ConsumerPriorityType(rawValue: $0.priorityType) ?? .secondary  })
    }
    
    var leftCapacity: Double {
        return generatorViewModel.capacity - totalConsumption
    }
    
    private func getConsumersForGroup(for category: ConsumerPriorityType) -> [ConsumerEntity] {
            return generatorViewModel.consumers.filter { $0.priorityType == category.rawValue }.sorted { $0.orderInGroup < $1.orderInGroup }
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
                moveItems(from: indices, to: newOffset, currentConsumersGroupPriorityType: group)
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
//                        GoogleSignInButton(action: handleSignInButton)
//                        Button("Sign out google") {
//                            signOutGoogle()
//                        }
                        
                        if allGeneratorConsumers.isEmpty {
                            Text("No consumers yet")
                        }
                        
                        if !allGeneratorConsumers.isEmpty {
                            ForEach(ConsumerPriorityType.allCases, id: \.self) { consumerPriorityType in
                                let consumersInGroup = getConsumersForGroup(for: consumerPriorityType)
                                
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
                                addNewConsumer()
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
                    ProgressView("Loading generator")
                }
            }
            .navigationTitle(generatorViewModel.name)
        }
        .sheet(isPresented: $addNewGeneratorConsumerState.isAddingNewConsumer, content: {
            if let currentGenerator = generatorViewModel.currentGenerator {
                let newConsumer = persistenceController.createLocalConsumer(for: currentGenerator)
                
                NavigationStack {
                    ConsumerView(consumer: newConsumer, isNewConsumer: true, consumersSections: consumersSections)
                        .onDisappear {
                            print("on disappear refresh from generatorview")
                            generatorViewModel.fetchGenerator()
                            allGeneratorConsumers = generatorViewModel.consumers
//                            print(allGeneratorConsumers)
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
    
    private func addNewConsumer() {
        addNewGeneratorConsumerState.isAddingNewConsumer = true
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
    
    private func moveItems(from source: IndexSet, to destination: Int, currentConsumersGroupPriorityType priorityTypeGroup: ConsumerPriorityType) {
//        debugPrint(consumersSections)
//        switch priorityTypeGroup.rawValue {
//        case 1:
//            moveItemWithinOrBetweenSections(from: source, to: destination, sourceArray: &section1Consumers, destinationArray: &section2Consumers, currentSection: 1)
//        case 2:
//            moveItemWithinOrBetweenSections(from: source, to: destination, sourceArray: &section2Consumers, destinationArray: &section1Consumers, currentSection: 2)
//        default:
//            break
//        }
//        var revisedItemsFromGroup = allGeneratorConsumers.map { $0 }.filter { $0.priorityType == priorityTypeGroup.rawValue }
//        revisedItemsFromGroup.move(fromOffsets: source, toOffset: destination)

//        for reverseIndex in stride(from: revisedItemsFromGroup.count - 1, through: 0, by: -1) {
//            revisedItemsFromGroup[reverseIndex].orderInGroup = Int16(reverseIndex)
//        }

//        viewContext.perform {
//            persistenceController.saveContext()
//        }
        
        var reorderedItems = getConsumersForGroup(for: priorityTypeGroup)
        reorderedItems.move(fromOffsets: source, toOffset: destination)

        // Avoid frequent context saves during the drag operation
        DispatchQueue.global(qos: .userInitiated).async {
            updateOrderInGroup(for: reorderedItems)
        }
    }
    
//    private func moveItemWithinOrBetweenSections(from source: IndexSet, to destination: Int, sourceArray: inout [ConsumerEntity], destinationArray: inout [ConsumerEntity], currentSection: Int) {
//        let sourceItem = source.map { sourceArray[$0] }
//
//        if currentSection == 1 && destination >= sourceArray.count {
//            // Moving from Section 1 to Section 2
//            sourceArray.remove(atOffsets: source)
//            destinationArray.insert(contentsOf: sourceItem, at: destination - sourceArray.count)
//            sourceItem.forEach { $0.priorityType = PriorityType.secondary.rawValue }
//        } else if currentSection == 2 && destination >= sourceArray.count {
//            // Moving from Section 2 to Section 1
//            sourceArray.remove(atOffsets: source)
//            destinationArray.insert(contentsOf: sourceItem, at: destination - sourceArray.count)
//            sourceItem.forEach { $0.priorityType = PriorityType.main.rawValue }
//        } else {
//            // Moving within the same section
//            sourceArray.move(fromOffsets: source, toOffset: destination)
//        }
//
//        // Update orderInGroup in both sections
//        updateOrderInGroup(for: &section1Consumers)
//        updateOrderInGroup(for: &section2Consumers)
//    }
    
    private func updateOrderInGroup(for consumers: [ConsumerEntity]) {
        // Batch the updates to avoid performance issues
        for (index, consumer) in consumers.enumerated() {
            consumer.orderInGroup = Int16(index)
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
