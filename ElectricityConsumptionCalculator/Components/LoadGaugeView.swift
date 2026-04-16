//
//  LoadGaugeView.swift
//  Electricity consumption calculator
//
//  Dashboard gauge showing load percentage with color-coded zones
//

import SwiftUI

struct LoadGaugeView: View {
    let loadPercentage: Double
    let loadStatus: LoadStatus
    let totalConsumption: Double
    let generatorCapacity: Double

    @State private var previousStatus: LoadStatus = .normal

    var body: some View {
        VStack(spacing: 16) {
            // Native SwiftUI Gauge with dynamic tint
            Gauge(value: min(loadPercentage, 100), in: 0...100) {
                Text("Load")
            } currentValueLabel: {
                Text("\(Int(loadPercentage))%")
                    .font(.title2.bold())
            } minimumValueLabel: {
                Text("0 W")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("\(Int(generatorCapacity)) W")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(loadStatus.color)
            .animation(.easeInOut(duration: 0.3), value: loadPercentage)
            .accessibilityLabel("Load at \(Int(loadPercentage)) percent, \(loadStatus.shortLabel)")
            .accessibilityValue("\(Int(loadPercentage)) percent")

            // Compact status row
            HStack(spacing: 8) {
                Text(loadStatus.emoji)
                Text("\(Int(loadPercentage))%")
                    .fontWeight(.semibold)
                Text(String(localized: loadStatus.shortLabel))
            }
            .font(.subheadline)
            .foregroundStyle(loadStatus.color)
            .accessibilityElement(children: .combine)
        }
        .padding(.vertical, 8)
        .onChange(of: loadStatus) { newStatus in
            // Haptic feedback on threshold crossings
            if newStatus != previousStatus {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(newStatus == .overload ? .error : .warning)
                previousStatus = newStatus
            }
        }
        .onAppear {
            previousStatus = loadStatus
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadGaugeView(
            loadPercentage: 45,
            loadStatus: .normal,
            totalConsumption: 2250,
            generatorCapacity: 5000
        )

        LoadGaugeView(
            loadPercentage: 75,
            loadStatus: .caution,
            totalConsumption: 3750,
            generatorCapacity: 5000
        )

        LoadGaugeView(
            loadPercentage: 135,
            loadStatus: .overload,
            totalConsumption: 6750,
            generatorCapacity: 5000
        )
    }
    .padding()
}
