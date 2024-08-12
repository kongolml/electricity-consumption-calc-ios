//
//  GeneratorEntity+CoreDataProperties.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 28.07.2024.
//
//

import Foundation
import CoreData


extension GeneratorEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeneratorEntity> {
        return NSFetchRequest<GeneratorEntity>(entityName: "GeneratorEntity")
    }

    @NSManaged public var capacity: Double
    @NSManaged public var dbid: String?
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var updatedAt: Date
    @NSManaged public var createdAt: Date
    @NSManaged public var consumers: NSSet?

}

// MARK: Generated accessors for consumers
extension GeneratorEntity {

    @objc(addConsumersObject:)
    @NSManaged public func addToConsumers(_ value: ConsumerEntity)

    @objc(removeConsumersObject:)
    @NSManaged public func removeFromConsumers(_ value: ConsumerEntity)

    @objc(addConsumers:)
    @NSManaged public func addToConsumers(_ values: NSSet)

    @objc(removeConsumers:)
    @NSManaged public func removeFromConsumers(_ values: NSSet)

}

extension GeneratorEntity : Identifiable {

}
