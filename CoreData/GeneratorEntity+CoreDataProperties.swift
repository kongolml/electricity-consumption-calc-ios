//
//  GeneratorEntity+CoreDataProperties.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 07.07.2024.
//
//

import Foundation
import CoreData


extension GeneratorEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeneratorEntity> {
        return NSFetchRequest<GeneratorEntity>(entityName: "GeneratorEntity")
    }

    @NSManaged public var name: String
    @NSManaged public var capacity: Double
    @NSManaged public var id: UUID?
    @NSManaged public var brand: String?
    @NSManaged public var peakCapacity: Double
    @NSManaged public var fuelTankCapacity: Double
    @NSManaged public var fuelType: Int16
    @NSManaged public var fuelConsumptionRate: Double
    @NSManaged public var isSelected: Bool
    @NSManaged public var consumers: NSSet?

}

extension GeneratorEntity : Identifiable {

}
