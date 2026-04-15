//
//  LoadGaugeView.swift
//  Electricity consumption calculator
//
//  Visual load gauge for the dashboard
//

import SwiftUI

struct LoadGaugeView: View {
    let loadPercentage: Double
    let currentConsumption: Double
    let maxCapacity: Double
    
    private var clampedPercentage: Double {
        min(max(loadPercentage, 0), 1.5) // Clamp between 0% and 150%
    }
    
    private var loadColor: Color {
        switch loadPercentage {
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
    
    private var isOverloaded: Bool {
        loadPercentage > 1.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Gauge
            Gauge(value: clampedPercentage, in: 0...1.5) {
                Text("Load")
            } currentValueLabel: {
                Text("\(Int(loadPercentage * 100))%")
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(loadColor)
            .frame(height: 120)
            
            // Warning icon for overload
            if isOverloaded {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Overload")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Power summary
            VStack(spacing: 4) {
                HStack {
                    Text("\(convertEnergyDoubleToNiceFormat(value: currentConsumption)) W")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Text("/")
                        .foregroundStyle(.secondary)
                    Text("\(convertEnergyDoubleToNiceFormat(value: maxCapacity)) W")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                if isOverloaded {
                    let overloadAmount = currentConsumption - maxCapacity
                    Text("+\(convertEnergyDoubleToNiceFormat(value: overloadAmount)) W over limit")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Generator load: \(Int(loadPercentage * 100)) percent")
        .accessibilityValue("\(convertEnergyDoubleToNiceFormat(value: currentConsumption)) watts of \(convertEnergyDoubleToNiceFormat(value: maxCapacity)) watts capacity")
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadGaugeView(loadPercentage: 0.45, currentConsumption: 2250, maxCapacity: 5000)
        LoadGaugeView(loadPercentage: 0.75, currentConsumption: 3750, maxCapacity: 5000)
        LoadGaugeView(loadPercentage: 0.95, currentConsumption: 4750, maxCapacity: 5000)
        LoadGaugeView(loadPercentage: 1.15, currentConsumption: 5750, maxCapacity: 5000)
    }
    .padding()
}
