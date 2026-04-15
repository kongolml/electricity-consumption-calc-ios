//
//  FuelRuntimeView.swift
//  Electricity consumption calculator
//
//  Fuel level and runtime estimation view
//

import SwiftUI

struct FuelRuntimeView: View {
    let generator: GeneratorEntity
    let consumers: [ConsumerEntity]

    @State private var fuelLevel: Double = 1.0 // Default to 100%

    private var fuelEnabled: Bool {
        generator.fuelTankCapacity > 0
    }

    private var runtime: TimeInterval? {
        ConsumptionCalculator.estimatedRuntime(generator: generator, consumers: consumers, fuelLevel: fuelLevel)
    }

    private var consumptionPerHour: Double? {
        ConsumptionCalculator.fuelConsumptionPerHour(generator: generator, consumers: consumers)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "fuel.pump.fill")
                    .font(.title2)
                    .foregroundStyle(fuelColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Fuel & Runtime")
                        .font(.headline)
                    Text("Estimated runtime based on current load")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Fuel level slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Fuel Level")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(fuelLevel * 100))%")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(fuelColor)
                }

                Slider(value: $fuelLevel, in: 0...1, step: 0.05)

                HStack {
                    Text("Empty")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Full (\(Int(generator.fuelTankCapacity)) L)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Runtime display
            if let runtime = runtime {
                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated Runtime")
                            .font(.subheadline)
                        Text(formattedRuntime(runtime))
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(runtimeColor(for: runtime))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Consumption")
                            .font(.subheadline)
                        if let consumption = consumptionPerHour {
                            Text("\(String(format: "%.2f", consumption)) L/h")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("Add active consumers to see runtime estimate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }

    private var fuelColor: Color {
        switch fuelLevel {
        case 0..<0.2:
            return .red
        case 0.2..<0.5:
            return .orange
        default:
            return .green
        }
    }

    private var backgroundColor: Color {
        switch fuelLevel {
        case 0..<0.2:
            return Color.red.opacity(0.05)
        case 0.2..<0.5:
            return Color.orange.opacity(0.05)
        default:
            return Color.green.opacity(0.05)
        }
    }

    private func runtimeColor(for runtime: TimeInterval) -> Color {
        let hours = runtime / 3600
        switch hours {
        case 0..<2:
            return .red
        case 2..<4:
            return .orange
        default:
            return .green
        }
    }

    private func formattedRuntime(_ runtime: TimeInterval) -> String {
        let hours = Int(runtime) / 3600
        let minutes = (Int(runtime) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let generator = GeneratorEntity.createMock(context: context)
    generator.fuelTankCapacity = 15
    generator.fuelConsumptionRate = 0.35

    let consumer = ConsumerEntity(context: context)
    consumer.name = "Test Device"
    consumer.consumption = 500
    consumer.isActive = true
    consumer.quantity = 1
    consumer.powerFactor = 1.0

    return VStack(spacing: 16) {
        FuelRuntimeView(generator: generator, consumers: [consumer])
    }
    .padding()
}
