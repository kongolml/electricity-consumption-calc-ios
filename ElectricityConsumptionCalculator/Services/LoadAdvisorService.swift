//
//  LoadAdvisorService.swift
//  Electricity consumption calculator
//
//  Service for providing load advice and recommendations
//

import Foundation
import SwiftUI

/// Protocol for load advisor functionality
protocol LoadAdvisorProtocol {
    func canAddDevice(watts: Double, surgeWatts: Double, generator: GeneratorEntity, consumers: [ConsumerEntity]) -> (runningSafe: Bool, surgeSafe: Bool)
    func devicesToTurnOff(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> [ConsumerEntity]
    func safeCombinations(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> [[ConsumerEntity]]
}

/// Environment key for LoadAdvisorService
private struct LoadAdvisorKey: EnvironmentKey {
    static let defaultValue: LoadAdvisorProtocol = LoadAdvisorService()
}

extension EnvironmentValues {
    var loadAdvisor: LoadAdvisorProtocol {
        get { self[LoadAdvisorKey.self] }
        set { self[LoadAdvisorKey.self] = newValue }
    }
}

/// Main load advisor service implementation
struct LoadAdvisorService: LoadAdvisorProtocol {
    func canAddDevice(watts: Double, surgeWatts: Double, generator: GeneratorEntity, consumers: [ConsumerEntity]) -> (runningSafe: Bool, surgeSafe: Bool) {
        ConsumptionCalculator.canAddDevice(watts: watts, surgeWatts: surgeWatts, generator: generator, consumers: consumers)
    }

    func devicesToTurnOff(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> [ConsumerEntity] {
        ConsumptionCalculator.suggestedDevicesToDisable(generator: generator, consumers: consumers)
    }

    func safeCombinations(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> [[ConsumerEntity]] {
        // Get active consumers sorted by priority (critical first, then important, then optional)
        let sortedConsumers = consumers.filter { $0.isActive }.sorted {
            let priority1 = ConsumerPriorityType(rawValue: $0.priorityType) ?? .critical
            let priority2 = ConsumerPriorityType(rawValue: $1.priorityType) ?? .critical
            return priority1.rawValue < priority2.rawValue
        }

        var combinations: [[ConsumerEntity]] = []
        var currentCombination: [ConsumerEntity] = []
        var currentLoad: Double = 0

        // Greedy algorithm: add devices until we reach capacity
        for consumer in sortedConsumers {
            let consumerLoad = ConsumptionCalculator.effectiveConsumption(for: consumer)
            if currentLoad + consumerLoad <= generator.capacity {
                currentCombination.append(consumer)
                currentLoad += consumerLoad
            } else {
                // Save current combination if it has devices
                if !currentCombination.isEmpty {
                    combinations.append(currentCombination)
                }
                // Start new combination with this device
                currentCombination = [consumer]
                currentLoad = consumerLoad
            }
        }

        // Add the last combination
        if !currentCombination.isEmpty {
            combinations.append(currentCombination)
        }

        return combinations
    }

    /// Checks if the current load is within safe limits
    func isLoadSafe(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> Bool {
        let loadPercentage = ConsumptionCalculator.loadPercentage(generator: generator, consumers: consumers)
        return loadPercentage <= 1.0 && ConsumptionCalculator.surgeIsSafe(generator: generator, consumers: consumers)
    }

    /// Gets a recommendation message based on current load
    func recommendationMessage(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> String {
        let loadPercentage = ConsumptionCalculator.loadPercentage(generator: generator, consumers: consumers)
        let surgeSafe = ConsumptionCalculator.surgeIsSafe(generator: generator, consumers: consumers)

        if loadPercentage > 1.0 {
            let toDisable = devicesToTurnOff(generator: generator, consumers: consumers)
            if toDisable.isEmpty {
                return "Load exceeds capacity. Consider reducing consumption."
            } else {
                let names = toDisable.prefix(3).map { $0.name }.joined(separator: ", ")
                return "Consider turning off: \(names)"
            }
        } else if !surgeSafe {
            return "Warning: Startup surge may exceed generator peak capacity."
        } else if loadPercentage > 0.8 {
            return "Running near capacity. Monitor load carefully."
        } else if loadPercentage > 0.5 {
            return "Good load balance. Room for more devices if needed."
        } else {
            return "Low load. Generator running efficiently."
        }
    }
}
