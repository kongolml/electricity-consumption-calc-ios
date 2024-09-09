//
//  ConsumerListItemView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI

struct ConsumerListItemView: View {
    @ObservedObject var consumer: ConsumerEntity

    var body: some View {
        HStack {
            Text(consumer.name)
            Spacer()
            Text("\(convertEnergyDoubleToNiceFormat(value: consumer.consumption)) Watt")
//            Text("x\(String(consumer.quantity))")
        }
        .opacity(consumer.isActive ? 1.0 : 0.5)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let defaultGenerator = PersistenceController.shared.fetchOrCreateDefaultGeneratorEntity()

    let dummyConsumer = ConsumerEntity.createMock(context: context, for: defaultGenerator)

    return ConsumerListItemView(consumer: dummyConsumer)
}
