//
//  ConsumerEntity+Custom.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 06.07.2024.
//

import Foundation
import CoreData

extension ConsumerEntity {
    override public func awakeFromInsert() {
        super.awakeFromInsert()

        self.id = UUID()
        self.name = NSLocalizedString("new_consumer_item_name", comment: "")
        self.consumption = 0
        self.priorityType = 1
        self.isActive = true
        self.quantity = 1
        self.createdAt = Date()
    }
    
    public static func createMock(context: NSManagedObjectContext) -> ConsumerEntity {
        let newConsumer = ConsumerEntity(context: context)
        newConsumer.id = UUID()
        newConsumer.name = NSLocalizedString("new_mock_consumer_item_name", comment: "")
        newConsumer.createdAt = Date()
        newConsumer.priorityType = Int16.random(in: 1...2)
        newConsumer.consumption = 100.0 //Double.random(in: 10.0...500.0)
        newConsumer.quantity = Int16.random(in: 1...5)
        newConsumer.isActive = Bool.random()
        newConsumer.orderInGroup = 0
        return newConsumer
    }
}
