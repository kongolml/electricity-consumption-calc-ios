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
            ConsumerPriorityType(rawValue: $0.priorityType) ?? .critical
        }
    }

    /// Returns load percentage (total consumption / generator capacity).
    /// Returns 0 when capacity is 0 or less.
    static func loadPercentage(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> Double {
        let capacity = generator.capacity
        guard capacity > 0 else { return 0 }
        let total = totalConsumption(for: consumers)
        return (total / capacity) * 100
    }

    /// Returns a LoadStatus enum value based on load percentage.
    /// 0-60% → .normal, 60-80% → .caution, 80-100% → .highLoad, >100% → .overload
    static func loadStatus(percentage: Double) -> LoadStatus {
        switch percentage {
        case ..<60:
            return .normal
        case 60..<80:
            return .caution
        case 80..<100:
            return .highLoad
        default:
            return .overload
        }
    }
}
