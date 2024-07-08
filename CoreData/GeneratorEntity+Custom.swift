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
    }

    public static func createMock(context: NSManagedObjectContext) -> GeneratorEntity {
        let newGenerator = GeneratorEntity(context: context)
        newGenerator.id = UUID()
        newGenerator.name = NSLocalizedString("new_mock_generator_item_name", comment: "")
        newGenerator.capacity = 1000
        return newGenerator
    }
}
