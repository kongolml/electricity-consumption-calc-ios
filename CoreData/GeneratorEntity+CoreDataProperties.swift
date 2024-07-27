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
    @NSManaged public var id: UUID
    @NSManaged public var updatedAt: Date
    @NSManaged public var dbid: String?

}

extension GeneratorEntity : Identifiable {

}
