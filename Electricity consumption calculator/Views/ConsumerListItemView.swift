//
//  ConsumerListItemView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI

struct ConsumerListItemView: View {
//    @EnvironmentObject var consumerViewModel: ConsumerViewModel
    @ObservedObject var consumer: ConsumerEntity
    
//    let consumerId: String
    
//    init(consumerId: UUID) {
//        self.consumerId = consumerId.uuidString
        
//        let model = ConsumerViewModel(context: PersistenceController.shared.container.viewContext)
//        model.fetchConsumerById(self.consumerId)
//        _consumerViewModel = StateObject(wrappedValue: model)
//        consumerViewModel.fetchConsumerById(self.consumerId)
//    }

    var body: some View {
        HStack {
            Text(consumer.name)
            Spacer()
            Text("\(convertEnergyDoubleToNiceFormat(value: consumer.consumption)) Watt")
            Text("x\(String(consumer.quantity))")
        }
        .opacity(consumer.isActive ? 1.0 : 0.5)
//        .onAppear {
//            consumerViewModel.fetchConsumerById(self.consumerId)
//        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let defaultGenerator = PersistenceController.shared.fetchOrCreateDefaultGeneratorEntity()

    let dummyConsumer = ConsumerEntity.createMock(context: context, for: defaultGenerator)

    return ConsumerListItemView(consumer: dummyConsumer)
}
