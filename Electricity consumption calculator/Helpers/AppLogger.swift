//
//  AppLogger.swift
//  Electricity consumption calculator
//
//  Created for centralized logging.
//

import Foundation
import os

/// Centralized logging utility for the application
enum AppLogger {
    static let auth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "Auth")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "Network")
    static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "Persistence")
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "UI")
    static let keychain = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.electricitycalculator", category: "Keychain")
}
