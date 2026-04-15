//
//  ConsumptionCalculator.swift
//  Electricity consumption calculator
//
//  Single source of truth for consumption calculation logic
//

import Foundation

struct ConsumptionCalculator {
    /// Calculates total consumption for a list of active consumers
    /// - Parameter consumers: Array of consumer entities
    /// - Returns: Sum of (consumption * quantity) for all active consumers
    static func totalConsumption(for consumers: [ConsumerEntity]) -> Double {
        consumers
            .filter { $0.isActive }
            .map { $0.consumption * Double($0.quantity) }
            .reduce(0, +)
    }
    
    /// Calculates remaining capacity after subtracting active consumption
    /// - Parameters:
    ///   - generator: The generator entity providing capacity
    ///   - consumers: Array of consumer entities
    /// - Returns: Generator capacity minus total consumption (can be negative)
    static func remainingCapacity(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> Double {
        generator.capacity - totalConsumption(for: consumers)
    }
    
    /// Groups consumers by their priority type
    /// - Parameter consumers: Array of consumer entities
    /// - Returns: Dictionary mapping priority types to their consumers
    static func groupedByPriority(consumers: [ConsumerEntity]) -> [ConsumerPriorityType: [ConsumerEntity]] {
        Dictionary(grouping: consumers) {
            ConsumerPriorityType(rawValue: $0.priorityType) ?? .main
        }
    }
}
