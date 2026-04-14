//
//  Electricity_consumption_calculatorApp.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI
import GoogleSignIn

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
                    .environmentObject(persistenceController)
                    .onAppear {
                        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                            guard let signedGoogleUser = user else {
                                print("No google user signed in")
                                return
                            }
                            
                            if let error = error {
                                print("Google sign-in error: \(error.localizedDescription)")
                                return
                            }
                            
                            print("Logged google user email: \(String(describing: signedGoogleUser.profile?.email))")
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
            // Handle error - maybe show error state
            print("❌ Failed to load or create default generator")
        }
        persistenceController.fetchConsumersOrCreateDefaults()
    }
}
