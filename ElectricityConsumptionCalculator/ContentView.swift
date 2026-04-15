//
//  ContentView.swift
//  Electricity consumption calculator
//
//  Created by OpenCode on 15.04.2026.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var generator: GeneratorEntity

    var body: some View {
        TabView {
            GeneratorView(generator: generator)
                .tabItem {
                    Label("Generator", systemImage: "bolt.fill")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    let persistenceController = PersistenceController.preview
    let viewContext = persistenceController.container.viewContext
    let dummyGenerator = GeneratorEntity.createMock(context: viewContext)

    return ContentView(generator: dummyGenerator)
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(persistenceController)
        .environment(\.keychainService, KeychainService.shared)
        .environment(\.authenticationService, AuthenticationService.shared)
}
