//
//  WhatToTurnOffView.swift
//  Electricity consumption calculator
//
//  View for suggesting devices to turn off to reduce load
//

import SwiftUI

struct WhatToTurnOffView: View {
    let generator: GeneratorEntity
    let consumers: [ConsumerEntity]

    @Environment(\.managedObjectContext) private var viewContext

    private var suggestions: [ConsumerEntity] {
        ConsumptionCalculator.suggestedDevicesToDisable(generator: generator, consumers: consumers)
    }

    private var currentLoad: Double {
        ConsumptionCalculator.totalConsumption(for: consumers)
    }

    private var isOverloaded: Bool {
        currentLoad > generator.capacity
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Current Load")
                    Spacer()
                    Text("\(convertEnergyDoubleToNiceFormat(value: currentLoad)) W")
                        .foregroundStyle(isOverloaded ? .red : .primary)
                }

                HStack {
                    Text("Capacity")
                    Spacer()
                    Text("\(convertEnergyDoubleToNiceFormat(value: generator.capacity)) W")
                        .foregroundStyle(.secondary)
                }

                if isOverloaded {
                    HStack {
                        Text("Overload")
                        Spacer()
                        Text("+\(convertEnergyDoubleToNiceFormat(value: currentLoad - generator.capacity)) W")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    }
                }
            }

            if suggestions.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.green)
                            Text("No suggestions needed")
                                .font(.headline)
                            Text("Load is within safe limits")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            } else {
                Section(header: Text("Suggested to Turn Off")) {
                    ForEach(suggestions, id: \.id) { consumer in
                        SuggestionRow(consumer: consumer) {
                            toggleConsumer(consumer)
                        }
                    }
                }

                Section(footer: Text("Devices are ordered by priority (optional first) and consumption (highest first).")) {
                    Button(action: turnOffAllSuggestions) {
                        HStack {
                            Spacer()
                            Text("Turn Off All Suggested")
                            Spacer()
                        }
                    }
                    .foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle("What to Turn Off?")
    }

    private func toggleConsumer(_ consumer: ConsumerEntity) {
        viewContext.perform {
            consumer.isActive.toggle()
            try? viewContext.save()
        }
    }

    private func turnOffAllSuggestions() {
        viewContext.perform {
            for consumer in suggestions {
                consumer.isActive = false
            }
            try? viewContext.save()
        }
    }
}

private struct SuggestionRow: View {
    let consumer: ConsumerEntity
    let onToggle: () -> Void

    private var priority: ConsumerPriorityType {
        ConsumerPriorityType(rawValue: consumer.priorityType) ?? .important
    }

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

            VStack(alignment: .leading, spacing: 2) {
                Text(consumer.name)
                    .font(.body)

                HStack(spacing: 8) {
                    Text(priority.name)
                        .font(.caption)
                        .foregroundStyle(priorityColor)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(convertEnergyDoubleToNiceFormat(value: ConsumptionCalculator.effectiveConsumption(for: consumer))) W")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onToggle) {
                Image(systemName: "power")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(width: 32, height: 32)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch priority {
        case .critical:
            return .red
        case .important:
            return .orange
        case .optional:
            return .green
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext

    let generator = GeneratorEntity(context: context)
    generator.id = UUID()
    generator.name = "Test Generator"
    generator.capacity = 1000

    let consumer1 = ConsumerEntity(context: context)
    consumer1.name = "Test Device"
    consumer1.consumption = 600
    consumer1.isActive = true
    consumer1.quantity = 1
    consumer1.powerFactor = 1.0
    consumer1.priorityType = ConsumerPriorityType.optional.rawValue

    let consumer2 = ConsumerEntity(context: context)
    consumer2.name = "Test Device 2"
    consumer2.consumption = 500
    consumer2.isActive = true
    consumer2.quantity = 1
    consumer2.powerFactor = 1.0
    consumer2.priorityType = ConsumerPriorityType.important.rawValue

    return NavigationStack {
        WhatToTurnOffView(generator: generator, consumers: [consumer1, consumer2])
    }
}
