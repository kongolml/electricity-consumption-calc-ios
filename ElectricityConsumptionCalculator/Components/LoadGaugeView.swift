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

    private var loadGauge: some View {
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
    }

    var body: some View {
        VStack(spacing: 16) {
            loadGauge
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.warning, trigger: loadStatus == .overload)
        .sensoryFeedback(.error, trigger: loadStatus == .overload)
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
