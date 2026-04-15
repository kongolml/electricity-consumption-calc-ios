//
//  CanIAddView.swift
//  Electricity consumption calculator
//
//  View for checking if a device can be safely added
//

import SwiftUI

struct CanIAddView: View {
    let generator: GeneratorEntity
    let consumers: [ConsumerEntity]

    @State private var selectedPreset: DevicePreset?
    @State private var customWatts: String = ""
    @State private var customSurgeWatts: String = ""
    @State private var showPresetPicker = false

    private var watts: Double {
        if let preset = selectedPreset {
            return preset.consumption
        }
        return Double(customWatts) ?? 0
    }

    private var surgeWatts: Double {
        if let preset = selectedPreset {
            return preset.surgeWattage
        }
        if let customSurge = Double(customSurgeWatts), customSurge > 0 {
            return customSurge
        }
        return watts // Default to running watts
    }

    private var result: (runningSafe: Bool, surgeSafe: Bool) {
        ConsumptionCalculator.canAddDevice(watts: watts, surgeWatts: surgeWatts, generator: generator, consumers: consumers)
    }

    var body: some View {
        Form {
            Section(header: Text("Device")) {
                Button(action: { showPresetPicker = true }) {
                    HStack {
                        Text("Select from Presets")
                        Spacer()
                        if let preset = selectedPreset {
                            Text(LocalizedStringKey(preset.name))
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if selectedPreset == nil {
                    TextField("Running Watts", text: $customWatts)
                        .keyboardType(.decimalPad)

                    TextField("Surge Watts (optional)", text: $customSurgeWatts)
                        .keyboardType(.decimalPad)
                }
            }

            if watts > 0 {
                Section(header: Text("Result")) {
                    ResultRow(
                        title: "Running Load",
                        isSafe: result.runningSafe,
                        current: ConsumptionCalculator.totalConsumption(for: consumers),
                        proposed: watts,
                        max: generator.capacity
                    )

                    if generator.peakCapacity > 0 {
                        ResultRow(
                            title: "Surge Load",
                            isSafe: result.surgeSafe,
                            current: ConsumptionCalculator.worstCaseSurge(for: consumers),
                            proposed: surgeWatts,
                            max: generator.peakCapacity
                        )
                    }

                    HStack {
                        Image(systemName: result.runningSafe && result.surgeSafe ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(result.runningSafe && result.surgeSafe ? .green : .red)

                        VStack(alignment: .leading) {
                            Text(result.runningSafe && result.surgeSafe ? "Safe to Add" : "Not Recommended")
                                .font(.headline)
                            if !(result.runningSafe && result.surgeSafe) {
                                Text("May exceed generator capacity")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Can I Add?")
        .sheet(isPresented: $showPresetPicker) {
            NavigationStack {
                PresetCategoryListView { category in
                    // Navigate to presets for this category
                }
                .navigationTitle("Select Device")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showPresetPicker = false
                        }
                    }
                }
            }
        }
    }
}

private struct ResultRow: View {
    let title: String
    let isSafe: Bool
    let current: Double
    let proposed: Double
    let max: Double

    private var total: Double { current + proposed }
    private var percentage: Double { max > 0 ? total / max : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: isSafe ? "checkmark.circle" : "exclamationmark.triangle")
                    .foregroundStyle(isSafe ? .green : .red)
            }
            .font(.subheadline)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: min(CGFloat(percentage) * geometry.size.width, geometry.size.width), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(current)) + \(Int(proposed)) = \(Int(total)) W")
                    .font(.caption)
                Spacer()
                Text("/ \(Int(max)) W")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var barColor: Color {
        switch percentage {
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
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let generator = GeneratorEntity.createMock(context: context)

    return NavigationStack {
        CanIAddView(generator: generator, consumers: [])
    }
}
