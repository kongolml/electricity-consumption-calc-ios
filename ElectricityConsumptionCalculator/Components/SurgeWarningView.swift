//
//  SurgeWarningView.swift
//  Electricity consumption calculator
//
//  Warning panel for surge capacity issues
//

import SwiftUI

struct SurgeWarningView: View {
    let generator: GeneratorEntity
    let consumers: [ConsumerEntity]

    private var worstCaseSurge: Double {
        ConsumptionCalculator.worstCaseSurge(for: consumers)
    }

    private var isSafe: Bool {
        ConsumptionCalculator.surgeIsSafe(generator: generator, consumers: consumers)
    }

    private var surgeRatio: Double {
        guard generator.peakCapacity > 0 else { return 0 }
        return worstCaseSurge / generator.peakCapacity
    }

    private var highSurgeConsumers: [ConsumerEntity] {
        consumers.filter { consumer in
            guard consumer.isActive else { return false }
            let surge = ConsumptionCalculator.surgeWattage(for: consumer)
            return surge > consumer.consumption * 1.5 // Significant surge
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: isSafe ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(isSafe ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isSafe ? "Surge Safe" : "Surge Warning")
                        .font(.headline)
                    Text("Worst-case startup surge analysis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Surge bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: min(CGFloat(surgeRatio) * geometry.size.width, geometry.size.width), height: 12)
                }
            }
            .frame(height: 12)

            // Numbers
            HStack {
                Text("\(convertEnergyDoubleToNiceFormat(value: worstCaseSurge)) W")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Text("/")
                    .foregroundStyle(.secondary)
                Text("\(convertEnergyDoubleToNiceFormat(value: generator.peakCapacity)) W peak")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(surgeRatio * 100))%")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(barColor)
            }

            // High surge devices warning
            if !isSafe && !highSurgeConsumers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("High surge devices:")
                        .font(.caption)
                        .fontWeight(.medium)

                    ForEach(highSurgeConsumers.prefix(3), id: \.id) { consumer in
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(consumer.name)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(ConsumptionCalculator.surgeWattage(for: consumer))) W surge")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var barColor: Color {
        switch surgeRatio {
        case 0..<0.6:
            return .green
        case 0.6..<0.8:
            return .yellow
        case 0.8..<1.0:
            return .orange
        default:
            return .red
        }
    }

    private var backgroundColor: Color {
        isSafe ? Color.green.opacity(0.05) : Color.red.opacity(0.05)
    }

    private var borderColor: Color {
        isSafe ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
    }
}

#Preview {
    SurgeWarningView_Previews()
}

private struct SurgeWarningView_Previews: View {
    let context = PersistenceController.preview.container.viewContext

    var body: some View {
        // Danger scenario
        let generator = GeneratorEntity(context: context)
        generator.id = UUID()
        generator.name = "Test Generator"
        generator.capacity = 5000
        generator.peakCapacity = 3000

        let consumer1 = ConsumerEntity(context: context)
        consumer1.name = "AC Unit"
        consumer1.consumption = 1000
        consumer1.surgeWattage = 2500
        consumer1.isActive = true
        consumer1.quantity = 1
        consumer1.powerFactor = 1.0

        let consumer2 = ConsumerEntity(context: context)
        consumer2.name = "Fridge"
        consumer2.consumption = 150
        consumer2.surgeWattage = 800
        consumer2.isActive = true
        consumer2.quantity = 1
        consumer2.powerFactor = 1.0

        // Safe scenario
        let safeGenerator = GeneratorEntity(context: context)
        safeGenerator.id = UUID()
        safeGenerator.name = "Safe Generator"
        safeGenerator.capacity = 5000
        safeGenerator.peakCapacity = 5000

        return VStack(spacing: 16) {
            SurgeWarningView(generator: generator, consumers: [consumer1, consumer2])
            SurgeWarningView(generator: safeGenerator, consumers: [consumer1, consumer2])
        }
        .padding()
    }
}
