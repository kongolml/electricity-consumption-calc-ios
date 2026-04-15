//
//  ConsumerListItemView.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 04.07.2024.
//

import SwiftUI

struct ConsumerListItemView: View {
    @ObservedObject var consumer: ConsumerEntity
    @Environment(\.managedObjectContext) private var viewContext

    private var category: DeviceCategory {
        DeviceCategory(rawValue: consumer.category) ?? .other
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: category.iconName)
                .font(.callout)
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .background(Color(.systemGray5))
                .cornerRadius(6)

            // Name and details
            VStack(alignment: .leading, spacing: 2) {
                Text(consumer.name)
                    .font(.body)

                HStack(spacing: 8) {
                    Text("\(convertEnergyDoubleToNiceFormat(value: consumer.consumption)) W")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if consumer.surgeWattage > consumer.consumption {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Quantity and toggle
            HStack(spacing: 8) {
                Text("x\(String(consumer.quantity))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Inline power toggle
                Button(action: {
                    toggleActive()
                }) {
                    Image(systemName: consumer.isActive ? "power" : "poweroff")
                        .font(.caption)
                        .foregroundStyle(consumer.isActive ? .green : .gray)
                        .frame(width: 32, height: 32)
                        .background(consumer.isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(consumer.isActive ? 1.0 : 0.5)
    }

    private func toggleActive() {
        viewContext.perform {
            consumer.isActive.toggle()
            try? viewContext.save()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext

    let dummyConsumer = ConsumerEntity.createMock(context: context)

    return ConsumerListItemView(consumer: dummyConsumer)
}
