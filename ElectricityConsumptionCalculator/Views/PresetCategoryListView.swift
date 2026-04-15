//
//  PresetCategoryListView.swift
//  Electricity consumption calculator
//
//  Grid view of device categories for preset browsing
//

import SwiftUI

struct PresetCategoryListView: View {
    let onSelectCategory: (DeviceCategory) -> Void

    private var presetsByCategory: [DeviceCategory: [DevicePreset]] {
        DevicePreset.groupedByCategory()
    }

    private var categories: [DeviceCategory] {
        DeviceCategory.allCases.filter { presetsByCategory[$0]?.isEmpty == false }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(categories) { category in
                    CategoryCard(
                        category: category,
                        presetCount: presetsByCategory[category]?.count ?? 0
                    )
                    .onTapGesture {
                        onSelectCategory(category)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Select Category")
    }
}

private struct CategoryCard: View {
    let category: DeviceCategory
    let presetCount: Int

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.system(size: 32))
                .foregroundStyle(.tint)

            Text(category.name)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("\(presetCount) devices")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        PresetCategoryListView { category in
            print("Selected: \(category)")
        }
    }
}
