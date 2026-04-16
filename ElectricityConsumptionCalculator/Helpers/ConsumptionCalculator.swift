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
            .map { effectiveConsumption(for: $0) }
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

    // MARK: - Load Percentage

    /// Calculates load percentage (0.0 - 1.0+)
    /// - Parameters:
    ///   - generator: The generator entity
    ///   - consumers: Array of consumer entities
    /// - Returns: Load percentage as a decimal (e.g., 0.75 = 75%)
    static func loadPercentage(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> Double {
        guard generator.capacity > 0 else { return 0 }
        return totalConsumption(for: consumers) / generator.capacity
    }

    // MARK: - Effective Consumption

    /// Calculates effective consumption for a single consumer including power factor
    /// - Parameter consumer: The consumer entity
    /// - Returns: consumption * quantity * powerFactor (if active, else 0)
    static func effectiveConsumption(for consumer: ConsumerEntity) -> Double {
        guard consumer.isActive else { return 0 }
        return consumer.consumption * Double(consumer.quantity) * consumer.powerFactor
    }

    // MARK: - Surge Calculations

    /// Gets the surge wattage for a consumer
    /// - Parameter consumer: The consumer entity
    /// - Returns: surgeWattage if > 0, else consumption (1x running watts)
    static func surgeWattage(for consumer: ConsumerEntity) -> Double {
        guard consumer.isActive else { return 0 }
        if consumer.surgeWattage > 0 {
            return consumer.surgeWattage * Double(consumer.quantity)
        }
        return consumer.consumption * Double(consumer.quantity)
    }

    /// Calculates worst-case surge (sum of all active consumer surge values)
    /// - Parameter consumers: Array of consumer entities
    /// - Returns: Sum of all active consumer surge values
    static func worstCaseSurge(for consumers: [ConsumerEntity]) -> Double {
        consumers
            .filter { $0.isActive }
            .map { surgeWattage(for: $0) }
            .reduce(0, +)
    }

    /// Checks if surge is within safe limits
    /// - Parameters:
    ///   - generator: The generator entity
    ///   - consumers: Array of consumer entities
    /// - Returns: true if worst-case surge is within generator peak capacity
    static func surgeIsSafe(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> Bool {
        guard generator.peakCapacity > 0 else { return true }
        return worstCaseSurge(for: consumers) <= generator.peakCapacity
    }

    // MARK: - Load Advisor

    /// Suggests devices to disable to bring load within capacity
    /// - Parameters:
    ///   - generator: The generator entity
    ///   - consumers: Array of consumer entities
    /// - Returns: Array of consumers to disable, ordered by priority (optional first)
    static func suggestedDevicesToDisable(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> [ConsumerEntity] {
        let overload = totalConsumption(for: consumers) - generator.capacity
        guard overload > 0 else { return [] }

        // Sort by priority (optional first), then by consumption (highest first)
        let activeConsumers = consumers.filter { $0.isActive }.sorted {
            let priority1 = ConsumerPriorityType(rawValue: $0.priorityType) ?? .critical
            let priority2 = ConsumerPriorityType(rawValue: $1.priorityType) ?? .critical
            if priority1.rawValue != priority2.rawValue {
                return priority1.rawValue > priority2.rawValue // Higher raw value = lower priority
            }
            return $0.consumption > $1.consumption
        }

        var toDisable: [ConsumerEntity] = []
        var remainingOverload = overload

        for consumer in activeConsumers {
            guard remainingOverload > 0 else { break }
            toDisable.append(consumer)
            remainingOverload -= effectiveConsumption(for: consumer)
        }

        return toDisable
    }

    /// Checks if a new device can be added safely
    /// - Parameters:
    ///   - watts: Running watts of the new device
    ///   - surgeWatts: Surge watts of the new device
    ///   - generator: The generator entity
    ///   - consumers: Current array of consumer entities
    /// - Returns: Tuple indicating running capacity safety and surge safety
    static func canAddDevice(watts: Double, surgeWatts: Double, generator: GeneratorEntity, consumers: [ConsumerEntity]) -> (runningSafe: Bool, surgeSafe: Bool) {
        let currentConsumption = totalConsumption(for: consumers)
        let currentSurge = worstCaseSurge(for: consumers)

        let runningSafe = currentConsumption + watts <= generator.capacity
        let surgeSafe = generator.peakCapacity <= 0 || currentSurge + surgeWatts <= generator.peakCapacity

        return (runningSafe, surgeSafe)
    }

    // MARK: - Fuel & Runtime

    /// Estimates runtime based on fuel level and consumption
    /// - Parameters:
    ///   - generator: The generator entity
    ///   - consumers: Array of consumer entities
    ///   - fuelLevel: Current fuel level as percentage (0.0 - 1.0)
    /// - Returns: Estimated runtime in seconds, or nil if no tank data
    static func estimatedRuntime(generator: GeneratorEntity, consumers: [ConsumerEntity], fuelLevel: Double) -> TimeInterval? {
        guard generator.fuelTankCapacity > 0, generator.fuelConsumptionRate > 0 else { return nil }

        let currentLoad = totalConsumption(for: consumers) / 1000.0 // Convert to kW
        guard currentLoad > 0 else { return nil }

        let availableFuel = generator.fuelTankCapacity * fuelLevel
        let hourlyConsumption = currentLoad * generator.fuelConsumptionRate

        let hours = availableFuel / hourlyConsumption
        return hours * 3600 // Convert to seconds
    }

    /// Calculates fuel consumption at current load
    /// - Parameters:
    ///   - generator: The generator entity
    ///   - consumers: Array of consumer entities
    /// - Returns: Liters per hour at current load
    static func fuelConsumptionPerHour(generator: GeneratorEntity, consumers: [ConsumerEntity]) -> Double? {
        guard generator.fuelConsumptionRate > 0 else { return nil }

        let currentLoad = totalConsumption(for: consumers) / 1000.0 // Convert to kW
        return currentLoad * generator.fuelConsumptionRate
    }
}
