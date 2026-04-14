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
import os

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

    private var consumersByPriority: [ConsumerPriorityType: [ConsumerEntity]] {
        Dictionary(grouping: allGeneratorConsumers, by: { ConsumerPriorityType(rawValue: $0.priorityType) ?? .secondary })
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
                        let consumersInGroup = consumersByPriority[filteredConsumersGroup] ?? []

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
                            addNewItem(priority: .main)
                        }) {
                            Label("Main device", systemImage: "refrigerator")
                        }

                        Button(action: {
                            addNewItem(priority: .secondary)
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

    private func addNewItem(priority: ConsumerPriorityType) {
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
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { [weak self] signInResult, error in
            if let error {
                Logger.auth.error("Sign in failed: \(error.localizedDescription)")
                return
            }
            guard let signInResult else { return }

            signInResult.user.refreshTokensIfNeeded { user, error in
                if let error {
                    Logger.auth.error("Token refresh failed: \(error.localizedDescription)")
                    return
                }
                guard let user else { return }
                guard let idToken = user.idToken?.tokenString else {
                    Logger.auth.error("No ID token available from Google Sign-In")
                    return
                }

                self?.exchangeGoogleToken(idToken: idToken)
            }
        }
    }

    func exchangeGoogleToken(idToken: String) {
        AuthenticationService.shared.signInWithGoogleToken(idToken: idToken) { tokens, error in
            if let error {
                Logger.auth.error("Auth exchange failed: \(error.localizedDescription)")
                return
            }
            guard let tokens else {
                Logger.auth.error("No tokens received from authentication service")
                return
            }

            KeychainService.shared.setUserApiToken(newToken: tokens.accessToken)
            Logger.auth.info("Access token saved successfully")

            if let refreshToken = tokens.refreshToken {
                KeychainService.shared.setRefreshToken(value: refreshToken)
                Logger.auth.info("Refresh token saved successfully")
            }
        }
    }

    func signOutGoogle() {
        GIDSignIn.sharedInstance.signOut()
        KeychainService.shared.clearAllTokens()
        Logger.auth.info("User signed out, all tokens cleared")
    }
}

extension Logger {
    static let auth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "Auth")
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
