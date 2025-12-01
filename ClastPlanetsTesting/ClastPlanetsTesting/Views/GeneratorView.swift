//
//  GeneratorView.swift
//  ClastPlanetsTesting
//
//  Screen for generating and discovering new planets
//

import SwiftUI

struct GeneratorView: View {
    @Environment(GalaxyViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Distance slider section
                    distanceSliderSection

                    // Planet preview
                    if let planet = viewModel.currentPreviewPlanet {
                        planetPreviewSection(planet: planet)
                    }

                    // Discover button
                    discoverButton

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Planet Generator")
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    // MARK: - Distance Slider Section

    private var distanceSliderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Distance Travelled")
                .font(.headline)

            HStack {
                Text("0")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(
                    value: Binding(
                        get: { viewModel.totalDistanceTravelled },
                        set: { newValue in
                            viewModel.totalDistanceTravelled = newValue
                            viewModel.generatePreviewPlanet()
                        }
                    ),
                    in: 0...100_000,
                    step: 100
                )

                Text("100k")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(Int(viewModel.totalDistanceTravelled).formatted()) km")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    // MARK: - Planet Preview Section

    private func planetPreviewSection(planet: Planet) -> some View {
        VStack(spacing: 16) {
            // Planet visualization
            PlanetView(planet: planet, size: 250)
                .padding()

            // Planet info card
            VStack(spacing: 12) {
                Text(planet.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 4) {
                    Text(planet.rarity.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(planet.rarity.color)
                        .cornerRadius(8)

                    Spacer()

                    Text("Seed: \(planet.seed)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Traits
                VStack(alignment: .leading, spacing: 8) {
                    traitRow(label: "Base", value: planet.baseType.rawValue.capitalized)
                    traitRow(label: "Rings", value: planet.ringType.rawValue.capitalized)
                    traitRow(label: "Moons", value: "\(planet.moonCount)")
                    traitRow(label: "Atmosphere", value: planet.atmosphereType.rawValue.capitalized)
                    traitRow(label: "Size", value: "\(planet.sizeClass.displayName) (\(String(format: "%.2f", planet.size)))")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }

    private func traitRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Discover Button

    private var discoverButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.discoverPlanet()
            }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Discover Planet")
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
    }
}

#Preview {
    GeneratorView()
        .environment(GalaxyViewModel())
}
