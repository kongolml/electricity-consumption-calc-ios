//
//  ConsumerEntity+CoreDataProperties.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 28.07.2024.
//
//

import Foundation
import CoreData


extension ConsumerEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConsumerEntity> {
        return NSFetchRequest<ConsumerEntity>(entityName: "ConsumerEntity")
    }

    @NSManaged public var consumption: Double
    @NSManaged public var id: UUID?
    @NSManaged public var isActive: Bool
    @NSManaged public var name: String
    @NSManaged public var orderInGroup: Int16
    @NSManaged public var priorityType: Int16
    @NSManaged public var quantity: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date
    @NSManaged public var dbid: String?
    @NSManaged public var generator: GeneratorEntity?

}

extension ConsumerEntity : Identifiable {

}
