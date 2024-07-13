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

struct GeneratorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var persistenceController: PersistenceController

    @ObservedObject var generator: GeneratorEntity

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ConsumerEntity.orderInGroup, ascending: true)],
        animation: .default)
    private var allGeneratorConsumers: FetchedResults<ConsumerEntity>
    
    var totalConsumption: Double {
        return allGeneratorConsumers.filter { $0.isActive }.map { $0.consumption * Double($0.quantity) }.reduce(0, +)
    }
    
    var leftCapacity: Double {
        generator.capacity - totalConsumption
    }
    
    private func filteredItems(for category: ConsumerPriorityType) -> [ConsumerEntity] {
        return allGeneratorConsumers.filter { $0.priorityType == category.rawValue }
    }

    var body: some View {
        NavigationStack {
            List {
                GoogleSignInButton(action: handleSignInButton)
                Button("Sign out google") {
                    signOutGoogle()
                }

                if (allGeneratorConsumers.count == 0) {
                    Text("No consumers yet")
                }
                
                if (allGeneratorConsumers.count > 0) {
                    ForEach(ConsumerPriorityType.allCases, id: \.self) { filteredConsumersGroup in
                        let consumersInGroup = filteredItems(for: filteredConsumersGroup)
                        
                        Section(content: {
                            ForEach(consumersInGroup, id: \.self) { consumerItem in
                                NavigationLink {
                                    ConsumerView(consumer: consumerItem)
                                } label: {
                                    ConsumerListItemView(consumer: consumerItem)
                                }
                                .swipeActions(edge: .leading) {
                                    Button(action: {
                                        toggleItemActiveStatus(consumer: consumerItem)
                                    }) {
                                        consumerItem.isActive ? Label("Dectivate", systemImage: "bolt.slash") : Label("Activate", systemImage: "powercord")
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
                            //                        .onDelete(perform: deleteItemsInBulk)
                            .onMove { indices, newOffset in
                                moveItems(from: indices, to: newOffset, in: filteredConsumersGroup)
                            }
                        }, header: {
                            if consumersInGroup.count > 1 {
                                Text("\(filteredConsumersGroup.namePlural) consumers")
                            } else {
                                Text("\(filteredConsumersGroup.name) consumer")
                            }
                        }, footer: {
                            var consumersTotalConsumption: Double {
                                consumersInGroup.filter { $0.isActive }.map { $0.consumption * Double($0.quantity) }.reduce(0, +)
                            }
                            Text("Total: \(convertEnergyDoubleToNiceFormat(value: consumersTotalConsumption)) Watt")
                        })
                    }
                }
                
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        GeneratorDetailsView(generator: generator)
                    } label: {
                        Label("Edit generator", systemImage: "gear")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Menu {
                        Button(action: {
                            addINewtem(priority: .main)
                        }) {
                            Label("Main device", systemImage: "refrigerator")
                        }
                        
                        Button(action: {
                            addINewtem(priority: .secondary)
                        }) {
                            Label("Secondary device", systemImage: "lightbulb.2")
                        }
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(generator.name)
        }
    }

    private func addINewtem(priority: ConsumerPriorityType) {
        viewContext.perform {
            withAnimation {
                let newItem = ConsumerEntity(context: viewContext)
                newItem.priorityType = priority.rawValue
                
                persistenceController.saveContext()
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
        viewContext.perform {
            withAnimation {
                persistenceController.deleteItem(consumer: consumer)
            }
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
                        tokenSignInExample(idToken: idToken!.tokenString)
                    }
                }
        }
//      )
        print("handleSignInButton handleSignInButton handleSignInButton handleSignInButton")
    }
    
    func tokenSignInExample(idToken: String) {
        guard let authData = try? JSONEncoder().encode(["idToken": idToken]) else {
            return
        }
        let url = URL(string: "https://electriciy-consumptions.localbackend:8888/api/auth/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.uploadTask(with: request, from: authData) { data, response, error in
            // Handle response from your backend.
            print("here is data")
            debugPrint(data)
            print("here is response")
            debugPrint(response)
        }
        task.resume()
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

    return GeneratorView(generator: dummyGenerator).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
