//
//  GeneratorEntity+Custom.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//

import Foundation
import CoreData

extension GeneratorEntity {
    override public func awakeFromInsert() {
        super.awakeFromInsert()

        self.id = UUID()
        self.name = NSLocalizedString("new_generator_item_name", comment: "")
        self.capacity = 1000
        self.peakCapacity = 0
        self.fuelTankCapacity = 0
        self.fuelType = 0
        self.fuelConsumptionRate = 0.35
        self.isSelected = true
    }

    public static func createMock(context: NSManagedObjectContext) -> GeneratorEntity {
        let newGenerator = GeneratorEntity(context: context)
        newGenerator.id = UUID()
        newGenerator.name = NSLocalizedString("new_mock_generator_item_name", comment: "")
        newGenerator.capacity = 1000
        newGenerator.peakCapacity = 2000
        newGenerator.fuelTankCapacity = 15
        newGenerator.fuelType = 1
        newGenerator.fuelConsumptionRate = 0.35
        newGenerator.isSelected = true
        return newGenerator
    }
}
