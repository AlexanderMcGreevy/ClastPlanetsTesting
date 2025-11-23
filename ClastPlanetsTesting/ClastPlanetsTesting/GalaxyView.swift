//
//  GalaxyView.swift
//  ClastPlanetsTesting
//
//  Screen for viewing and selecting the active planet
//

import SwiftUI

struct GalaxyView: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @State private var showingPlanetPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let activePlanet = viewModel.activePlanet {
                        activePlanetSection(planet: activePlanet)
                    } else {
                        noPlanetState
                    }

                    // Statistics section
                    statisticsSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("My Galaxy")
            .background(
                // Starry background
                ZStack {
                    Color.black
                    starsBackground
                }
                .ignoresSafeArea()
            )
            .sheet(isPresented: $showingPlanetPicker) {
                PlanetPickerSheet()
                    .environment(viewModel)
            }
        }
    }

    // MARK: - Active Planet Section

    private func activePlanetSection(planet: Planet) -> some View {
        VStack(spacing: 20) {
            Text("Active Planet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            // Large planet display
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [planet.primaryColor.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 100,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)

                PlanetView(planet: planet, size: 280)
            }
            .padding()

            // Planet info
            VStack(spacing: 12) {
                Text(planet.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Text(planet.rarity.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(planet.rarity.color)
                        .cornerRadius(8)

                    Spacer()

                    Text("Discovered at \(Int(planet.distanceDiscoveredAt).formatted()) km")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal)

                Text(planet.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            // Change planet button
            Button {
                showingPlanetPicker = true
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Choose Active Planet")
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(viewModel.discoveredPlanets.count <= 1)
        }
    }

    // MARK: - No Planet State

    private var noPlanetState: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.3))

            Text("No Active Planet")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Discover a planet using the Generator tab to get started!")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                statRow(
                    icon: "sparkles",
                    label: "Total Planets",
                    value: "\(viewModel.totalPlanetsDiscovered)"
                )

                statRow(
                    icon: "location.fill",
                    label: "Distance Travelled",
                    value: "\(Int(viewModel.totalDistanceTravelled).formatted()) km"
                )

                Divider()
                    .background(Color.white.opacity(0.2))

                // Planets by rarity
                ForEach(Rarity.allCases.reversed(), id: \.self) { rarity in
                    if let count = viewModel.planetsByRarity[rarity], count > 0 {
                        HStack {
                            Circle()
                                .fill(rarity.color)
                                .frame(width: 12, height: 12)

                            Text(rarity.displayName)
                                .foregroundStyle(.white.opacity(0.8))

                            Spacer()

                            Text("\(count)")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 24)

            Text(label)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .font(.subheadline)
    }

    // MARK: - Stars Background

    private var starsBackground: some View {
        GeometryReader { geometry in
            ZStack {
                // Generate some random stars
                ForEach(0..<100, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.9)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height * 2)
                        )
                }
            }
        }
    }
}

// MARK: - Planet Picker Sheet

struct PlanetPickerSheet: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(viewModel.sortedPlanets) { planet in
                        PlanetPickerCard(
                            planet: planet,
                            isActive: viewModel.activePlanetID == planet.id
                        ) {
                            viewModel.setActivePlanet(planet)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Active Planet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Planet Picker Card

struct PlanetPickerCard: View {
    let planet: Planet
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    PlanetView(planet: planet, size: 120)

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .background(Circle().fill(Color.white))
                            .font(.title2)
                    }
                }

                VStack(spacing: 4) {
                    Text(planet.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(planet.rarity.displayName)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(planet.rarity.color)
                        .cornerRadius(4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.green : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let viewModel = GalaxyViewModel()
    viewModel.discoveredPlanets = [
        PlanetGenerator.generatePlanet(atDistance: 1000, seed: 1),
        PlanetGenerator.generatePlanet(atDistance: 25000, seed: 2),
        PlanetGenerator.generatePlanet(atDistance: 75000, seed: 3)
    ]
    viewModel.activePlanetID = viewModel.discoveredPlanets.first?.id

    return GalaxyView()
        .environment(viewModel)
}
