//
//  DevicePreset.swift
//  Electricity consumption calculator
//
//  Model for device presets loaded from bundled JSON
//

import Foundation
import CoreData

struct DevicePreset: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: Int16
    let consumption: Double
    let surgeWattage: Double
    let powerFactor: Double
    let dutyCycleType: Int16

    /// The category as an enum value
    var deviceCategory: DeviceCategory {
        DeviceCategory(rawValue: category) ?? .other
    }

    /// The duty cycle type as an enum value
    var dutyCycle: DutyCycleType {
        DutyCycleType(rawValue: dutyCycleType) ?? .manualOnOff
    }

    /// Loads all presets from the bundled JSON file
    static func loadAll() -> [DevicePreset] {
        guard let url = Bundle.main.url(forResource: "DevicePresets", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }

        let decoder = JSONDecoder()
        return (try? decoder.decode([DevicePreset].self, from: data)) ?? []
    }

    /// Groups presets by their category
    static func groupedByCategory() -> [DeviceCategory: [DevicePreset]] {
        let allPresets = loadAll()
        return Dictionary(grouping: allPresets) { $0.deviceCategory }
    }

    /// Creates a ConsumerEntity from this preset
    /// - Parameters:
    ///   - context: The managed object context
    ///   - generator: The generator to associate with
    /// - Returns: A new ConsumerEntity populated with preset values
    func createConsumer(in context: NSManagedObjectContext, for generator: GeneratorEntity) -> ConsumerEntity {
        let consumer = ConsumerEntity(context: context)
        consumer.name = NSLocalizedString(name, comment: "")
        consumer.category = category
        consumer.consumption = consumption
        consumer.surgeWattage = surgeWattage
        consumer.powerFactor = powerFactor
        consumer.dutyCycleType = dutyCycleType
        consumer.priorityType = ConsumerPriorityType.important.rawValue // Default to important
        consumer.quantity = 1
        consumer.isActive = true
        consumer.relationship = generator
        consumer.timeCreated = Date()
        return consumer
    }
}
