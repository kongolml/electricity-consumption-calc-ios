//
//  Electricity_consumption_calculatorApp.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI
import GoogleSignIn
import os

// MARK: - Environment Keys for Dependency Injection

extension EnvironmentValues {
    @Entry var keychainService: KeychainServiceProtocol = KeychainService.shared
    @Entry var authenticationService: AuthenticationServiceProtocol = AuthenticationService.shared
}

@main
struct Electricity_consumption_calculatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared
    @State private var defaultGenerator: GeneratorEntity?

    var body: some Scene {
        WindowGroup {
            if let generator = defaultGenerator {
                GeneratorView(generator: generator)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environment(\.keychainService, KeychainService.shared)
                    .environment(\.authenticationService, AuthenticationService.shared)
                    .environmentObject(persistenceController)
                    .onAppear {
                        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                            if let error {
                                Logger.auth.error("Google sign-in restore error: \(error.localizedDescription)")
                                return
                            }

                            guard let signedGoogleUser = user else {
                                Logger.auth.info("No google user signed in")
                                return
                            }

                            Logger.auth.info("Restored google user email: \(String(describing: signedGoogleUser.profile?.email))")
                        }
                    }
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
            } else {
                ProgressView("Loading")
                    .onAppear {
                        self.loadDefaultGenerator()
                    }
            }
        }
    }
    
    private func loadDefaultGenerator() {
        defaultGenerator = persistenceController.fetchOrCreateDefaultGeneratorEntity()
        if defaultGenerator == nil {
            Logger.persistence.error("Failed to load or create default generator")
        }
        persistenceController.fetchOrCreateDefaultConsumers()
    }
}
