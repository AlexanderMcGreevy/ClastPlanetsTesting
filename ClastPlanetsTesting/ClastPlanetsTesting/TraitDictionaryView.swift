//
//  TraitDictionaryView.swift
//  ClastPlanetsTesting
//
//  Dictionary view showing all possible planet traits organized by rarity
//

import SwiftUI

struct TraitDictionaryView: View {
    @Environment(GalaxyViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            List {
                // Base Type Section
                Section("Base Types") {
                    ForEach(BaseType.allCases, id: \.self) { baseType in
                        TraitRow(
                            name: baseType.rawValue.capitalized,
                            rarity: baseType.rarity,
                            isCollected: isBaseTypeCollected(baseType)
                        )
                    }
                }

                // Ring Type Section
                Section("Ring Types") {
                    ForEach(RingType.allCases.filter { $0 != .none }, id: \.self) { ringType in
                        TraitRow(
                            name: ringType.rawValue.capitalized,
                            rarity: ringType.rarity,
                            isCollected: isRingTypeCollected(ringType)
                        )
                    }
                }

                // Atmosphere Type Section
                Section("Atmosphere Types") {
                    ForEach(AtmosphereType.allCases.filter { $0 != .none }, id: \.self) { atmosphereType in
                        TraitRow(
                            name: atmosphereType.rawValue.capitalized,
                            rarity: atmosphereType.rarity,
                            isCollected: isAtmosphereTypeCollected(atmosphereType)
                        )
                    }
                }

                // Statistics Section
                Section("Collection Statistics") {
                    statisticsView
                }
            }
            .navigationTitle("Trait Dictionary")
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Statistics View

    private var statisticsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Rarity.allCases, id: \.self) { rarity in
                HStack {
                    Circle()
                        .fill(rarity.color)
                        .frame(width: 12, height: 12)

                    Text(rarity.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(collectedCount(for: rarity)) / \(totalCount(for: rarity))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Text("Total Traits")
                    .font(.headline)

                Spacer()

                Text("\(totalCollectedCount) / \(totalTraitCount)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helper Functions

    private func isBaseTypeCollected(_ baseType: BaseType) -> Bool {
        viewModel.discoveredPlanets.contains { $0.baseType == baseType }
    }

    private func isRingTypeCollected(_ ringType: RingType) -> Bool {
        viewModel.discoveredPlanets.contains { $0.ringType == ringType }
    }

    private func isAtmosphereTypeCollected(_ atmosphereType: AtmosphereType) -> Bool {
        viewModel.discoveredPlanets.contains { $0.atmosphereType == atmosphereType }
    }

    private func collectedCount(for rarity: Rarity) -> Int {
        var count = 0

        // Count base types
        count += BaseType.allCases.filter { $0.rarity == rarity && isBaseTypeCollected($0) }.count

        // Count ring types (excluding .none)
        count += RingType.allCases.filter { $0 != .none && $0.rarity == rarity && isRingTypeCollected($0) }.count

        // Count atmosphere types (excluding .none)
        count += AtmosphereType.allCases.filter { $0 != .none && $0.rarity == rarity && isAtmosphereTypeCollected($0) }.count

        return count
    }

    private func totalCount(for rarity: Rarity) -> Int {
        var count = 0

        // Count base types
        count += BaseType.allCases.filter { $0.rarity == rarity }.count

        // Count ring types (excluding .none)
        count += RingType.allCases.filter { $0 != .none && $0.rarity == rarity }.count

        // Count atmosphere types (excluding .none)
        count += AtmosphereType.allCases.filter { $0 != .none && $0.rarity == rarity }.count

        return count
    }

    private var totalCollectedCount: Int {
        Rarity.allCases.reduce(0) { $0 + collectedCount(for: $1) }
    }

    private var totalTraitCount: Int {
        Rarity.allCases.reduce(0) { $0 + totalCount(for: $1) }
    }
}

// MARK: - Trait Row

struct TraitRow: View {
    let name: String
    let rarity: Rarity
    let isCollected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rarity indicator
            Circle()
                .fill(rarity.color)
                .frame(width: 10, height: 10)
                .opacity(isCollected ? 1.0 : 0.3)

            // Trait name
            Text(name)
                .font(.body)
                .foregroundStyle(isCollected ? .primary : .secondary)
                .opacity(isCollected ? 1.0 : 0.5)

            Spacer()

            // Rarity badge
            Text(rarity.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(rarity.color)
                .cornerRadius(4)
                .opacity(isCollected ? 1.0 : 0.5)

            // Collection status icon
            Image(systemName: isCollected ? "checkmark.circle.fill" : "lock.circle.fill")
                .foregroundStyle(isCollected ? .green : .gray)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Dictionary - Empty") {
    TraitDictionaryView()
        .environment(GalaxyViewModel())
}

#Preview("Dictionary - With Planets") {
    let viewModel = GalaxyViewModel()
    viewModel.discoveredPlanets = [
        PlanetGenerator.generatePlanet(atDistance: 1000, seed: 1),
        PlanetGenerator.generatePlanet(atDistance: 25000, seed: 2),
        PlanetGenerator.generatePlanet(atDistance: 75000, seed: 3),
        PlanetGenerator.generatePlanet(atDistance: 95000, seed: 4)
    ]

    return TraitDictionaryView()
        .environment(viewModel)
}
