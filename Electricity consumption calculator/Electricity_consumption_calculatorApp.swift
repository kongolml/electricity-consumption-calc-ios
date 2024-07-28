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
//    @State private var generatorToUse
        
    let keychain = KeychainToolbox()
    let generatorMiddleware = GeneratorMiddleware()

    var body: some Scene {
        WindowGroup {
            if let generator = defaultGenerator {
                GeneratorView(generator: generator)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(persistenceController)
//                    .onAppear {
//                        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
//                            // Check if `user` exists; otherwise, do something with `error`
//                            guard let signedGoogleUser = user else {
//                                print("no google user, error?, check")
//                                return
//                            }
//                            
//                            if error != nil {
//                                debugPrint(error)
//                                return
//                            }
//                            
//                            print("logged google user email: \(String(describing: signedGoogleUser.profile?.email))")
//                        }
//                        self.loadDefaultGenerator()
//                    }
//                    .onOpenURL { url in
//                        GIDSignIn.sharedInstance.handle(url)
//                    }
            } else {
                ProgressView("Loading")
                    .onAppear {
                        self.loadData()
                    }
            }
        }
    }
    
    private func loadDefaultGenerator() -> Void {
        defaultGenerator = persistenceController.fetchOrCreateDefaultGeneratorEntity()
        persistenceController.fetchConsumersOrCreateDefaults()
    }
    
    private func loadData() {
//        TODO: move this logic away from here
        if (keychain.getUserApiToken() != nil) {
            generatorMiddleware.getUserGenerators(completion: { userGenerators, error  in
                if (userGenerators != nil) {
                    if (!userGenerators!.isEmpty) {
    //                    sync core data and data from server:
//                        persistenceController.saveGeneratorsToCoreData(generators: userGenerators!)
                    } else {
                        loadDefaultGenerator()
                    }
                }
                
                if (error != nil) {
                    loadDefaultGenerator()
                }
            })
        } else {
            loadDefaultGenerator()
        }
    }
}
