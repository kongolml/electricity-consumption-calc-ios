//
//  PresetListView.swift
//  Electricity consumption calculator
//
//  List of device presets for a specific category
//

import SwiftUI

struct PresetListView: View {
    let category: DeviceCategory
    let onSelectPreset: (DevicePreset) -> Void

    private var presets: [DevicePreset] {
        DevicePreset.loadAll().filter { $0.deviceCategory == category }
    }

    var body: some View {
        List(presets) { preset in
            PresetRow(preset: preset)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectPreset(preset)
                }
        }
        .navigationTitle(category.name)
    }
}

private struct PresetRow: View {
    let preset: DevicePreset

    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            Image(systemName: preset.deviceCategory.iconName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray5))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(preset.name))
                    .font(.body)

                HStack(spacing: 8) {
                    Label("\(Int(preset.consumption)) W", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if preset.surgeWattage > preset.consumption {
                        Label("\(Int(preset.surgeWattage)) W surge", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PresetListView(category: .kitchen) { preset in
            print("Selected: \(preset.name)")
        }
    }
}
