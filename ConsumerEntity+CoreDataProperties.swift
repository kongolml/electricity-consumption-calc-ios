//
//  ConsumerEntity+CoreDataProperties.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//
//

import Foundation
import CoreData


extension ConsumerEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConsumerEntity> {
        return NSFetchRequest<ConsumerEntity>(entityName: "ConsumerEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var consumption: Float
    @NSManaged public var priorityType: Int16
    @NSManaged public var isActive: Bool
    @NSManaged public var quantity: Int16
    @NSManaged public var timeCreated: Date

    override public func awakeFromInsert() {
        super.awakeFromInsert()

        self.id = UUID()
        self.name = "New Item"
        self.consumption = 0
        self.priorityType = 1
        self.isActive = true
        self.quantity = 1
        self.timeCreated = Date()
    }
}

extension ConsumerEntity : Identifiable {

}
