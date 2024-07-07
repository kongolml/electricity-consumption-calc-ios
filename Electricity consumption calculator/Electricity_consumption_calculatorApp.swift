//
//  Electricity_consumption_calculatorApp.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI

@main
struct Electricity_consumption_calculatorApp: App {
    let persistenceController = PersistenceController.shared
    @State private var defaultGenerator: GeneratorEntity?

    var body: some Scene {
        WindowGroup {
            if let generator = defaultGenerator {
                GeneratorView(generator: generator)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(persistenceController)
                    .onAppear {
                        self.loadDefaultGenerator()
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
    }
}
