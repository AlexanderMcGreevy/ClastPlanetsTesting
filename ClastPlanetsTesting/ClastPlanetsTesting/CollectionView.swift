//
//  CollectionView.swift
//  ClastPlanetsTesting
//
//  Screen showing all discovered planets with detail view
//

import SwiftUI

enum PlanetSortOption: String, CaseIterable {
    case distance = "Distance"
    case rarity = "Rarity"
    case name = "Name"
    case favorites = "Favorites"
}

struct CollectionView: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @State private var sortOption: PlanetSortOption = .distance
    @State private var showFavoritesOnly = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.discoveredPlanets.isEmpty {
                    emptyState
                } else {
                    planetList
                }
            }
            .navigationTitle("Collection")
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(PlanetSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }

                        Divider()

                        Toggle(isOn: $showFavoritesOnly) {
                            Label("Favorites Only", systemImage: "star.fill")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    // MARK: - Sorting

    private var sortedPlanets: [Planet] {
        var planets = switch sortOption {
        case .distance:
            viewModel.sortedPlanets
        case .rarity:
            viewModel.discoveredPlanets.sorted { p1, p2 in
                let order: [Rarity] = [.legendary, .rare, .uncommon, .common]
                let index1 = order.firstIndex(of: p1.rarity) ?? order.count
                let index2 = order.firstIndex(of: p2.rarity) ?? order.count
                return index1 < index2
            }
        case .name:
            viewModel.discoveredPlanets.sorted { $0.name < $1.name }
        case .favorites:
            viewModel.discoveredPlanets.sorted { p1, p2 in
                let fav1 = viewModel.isFavorited(p1)
                let fav2 = viewModel.isFavorited(p2)
                if fav1 != fav2 {
                    return fav1
                }
                return p1.distanceDiscoveredAt < p2.distanceDiscoveredAt
            }
        }

        if showFavoritesOnly {
            planets = planets.filter { viewModel.isFavorited($0) }
        }

        return planets
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Planets Discovered Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Use the Generator tab to discover your first planet!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Planet List

    private var planetList: some View {
        List {
            Section {
                ForEach(sortedPlanets) { planet in
                    NavigationLink {
                        PlanetDetailView(planet: planet)
                            .environment(viewModel)
                    } label: {
                        PlanetRow(planet: planet, viewModel: viewModel)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.toggleFavorite(planet)
                        } label: {
                            Label(
                                viewModel.isFavorited(planet) ? "Unfavorite" : "Favorite",
                                systemImage: viewModel.isFavorited(planet) ? "star.slash" : "star.fill"
                            )
                        }
                        .tint(.yellow)
                    }
                }
            } header: {
                HStack {
                    Text("\(viewModel.totalPlanetsDiscovered) Planets Discovered")
                    Spacer()
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Planet Row

struct PlanetRow: View {
    let planet: Planet
    let viewModel: GalaxyViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Small planet thumbnail
            PlanetView(planet: planet, size: 60)

            // Planet info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(planet.name)
                        .font(.headline)

                    if viewModel.isFavorited(planet) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    Text(planet.rarity.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(planet.rarity.color)
                        .cornerRadius(4)

                    Text("\(Int(planet.distanceDiscoveredAt).formatted()) km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(planet.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Planet Detail View

struct PlanetDetailView: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let planet: Planet

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Large planet preview
                PlanetView(planet: planet, size: 300)
                    .padding()

                // Planet details card
                VStack(spacing: 20) {
                    // Name and rarity
                    VStack(spacing: 8) {
                        Text(planet.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        HStack(spacing: 4) {
                            Text(planet.rarity.displayName)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(planet.rarity.color)
                                .cornerRadius(8)

                            Spacer()
                        }
                    }

                    Divider()

                    // Discovery info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Discovery Info")
                            .font(.headline)

                        detailRow(
                            icon: "location.fill",
                            label: "Distance",
                            value: "\(Int(planet.distanceDiscoveredAt).formatted()) km"
                        )

                        detailRow(
                            icon: "number",
                            label: "Seed",
                            value: "\(planet.seed)"
                        )
                    }

                    Divider()

                    // Traits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Traits")
                            .font(.headline)

                        detailRow(
                            icon: "circle.fill",
                            label: "Base Type",
                            value: planet.baseType.rawValue.capitalized,
                            badge: planet.baseType.rarity
                        )

                        detailRow(
                            icon: "circle.hexagongrid.fill",
                            label: "Rings",
                            value: planet.ringType.rawValue.capitalized,
                            badge: planet.ringType.rarity
                        )

                        detailRow(
                            icon: "moonphase.full.moon",
                            label: "Moons",
                            value: "\(planet.moonCount)"
                        )

                        detailRow(
                            icon: "cloud.fill",
                            label: "Atmosphere",
                            value: planet.atmosphereType.rawValue.capitalized,
                            badge: planet.atmosphereType.rarity
                        )

                        detailRow(
                            icon: "arrow.up.left.and.arrow.down.right",
                            label: "Size",
                            value: String(format: "%.2f", planet.size)
                        )
                    }

                    Divider()

                    // Colors
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color Palette")
                            .font(.headline)

                        HStack(spacing: 16) {
                            colorSwatch(color: planet.primaryColor, label: "Primary")
                            colorSwatch(color: planet.secondaryColor, label: "Secondary")
                            colorSwatch(color: planet.accentColor, label: "Accent")
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func detailRow(icon: String, label: String, value: String, badge: Rarity? = nil) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)

            if let badge = badge {
                Circle()
                    .fill(badge.color)
                    .frame(width: 8, height: 8)
            }
        }
        .font(.subheadline)
    }

    private func colorSwatch(color: Color, label: String) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color(uiColor: .systemGray4), lineWidth: 2)
                )

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Collection - Empty") {
    CollectionView()
        .environment(GalaxyViewModel())
}

#Preview("Collection - With Planets") {
    let viewModel = GalaxyViewModel()
    viewModel.discoveredPlanets = [
        PlanetGenerator.generatePlanet(atDistance: 1000, seed: 1),
        PlanetGenerator.generatePlanet(atDistance: 25000, seed: 2),
        PlanetGenerator.generatePlanet(atDistance: 75000, seed: 3)
    ]

    return CollectionView()
        .environment(viewModel)
}
