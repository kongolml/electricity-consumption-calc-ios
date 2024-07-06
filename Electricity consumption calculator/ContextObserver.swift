//
//  ContextObserver.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 06.07.2024.
//

import Foundation
import CoreData
import Combine

class ContextObserver: ObservableObject {
    @Published var didChange = false
    private var context: NSManagedObjectContext
    private var cancellable: AnyCancellable?

    init(context: NSManagedObjectContext) {
        self.context = context
        self.cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .sink { [weak self] _ in
                self?.didChange.toggle()
            }
    }
}
