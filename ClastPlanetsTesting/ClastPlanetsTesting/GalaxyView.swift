//
//  GalaxyView.swift
//  ClastPlanetsTesting
//
//  Screen for viewing multiple planets orbiting a central sun
//

import SwiftUI

struct GalaxyView: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @State private var showingPlanetPicker = false
    @State private var selectedPlanetIDs: Set<UUID> = []
    @State private var zoomScale: CGFloat = 1.0
    @State private var ringSpacing: CGFloat = 1.0 // Adjustable ring spacing multiplier
    @State private var planetOrbits: [UUID: Int] = [:] // Track which orbit each planet is on
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                // Starry background
                Color.black.ignoresSafeArea()
                starsBackground

                if viewModel.discoveredPlanets.isEmpty {
                    noPlanetState
                } else {
                    VStack(spacing: 0) {
                        // Galaxy view with orbiting planets
                        solarSystemView
                            .frame(maxHeight: .infinity)
                            .scaleEffect(zoomScale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        zoomScale = min(max(value, 0.5), 3.0)
                                    }
                            )

                        // Bottom controls
                        controlsSection
                            .background(Color.black.opacity(0.8))
                    }
                }
            }
            .navigationTitle("My Galaxy")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingPlanetPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.white)
                    }
                    .disabled(viewModel.discoveredPlanets.isEmpty)
                }
            }
            .sheet(isPresented: $showingPlanetPicker) {
                SimplePlanetSelectionSheet(selectedPlanetIDs: $selectedPlanetIDs)
                    .environment(viewModel)
            }
            .onAppear {
                // Auto-select up to 6 planets on first load
                if selectedPlanetIDs.isEmpty {
                    selectedPlanetIDs = Set(viewModel.sortedPlanets.prefix(min(6, viewModel.sortedPlanets.count)).map { $0.id })
                }
                // Initialize planet orbits
                if planetOrbits.isEmpty {
                    for (index, planet) in viewModel.discoveredPlanets.prefix(selectedPlanetIDs.count).enumerated() {
                        planetOrbits[planet.id] = index
                    }
                }
            }
        }
    }

    // MARK: - Solar System View

    private var solarSystemView: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let center = CGPoint(x: centerX, y: centerY)
            let maxRadius = min(geometry.size.width, geometry.size.height) * 0.45
            let selectedPlanets = viewModel.discoveredPlanets.filter { selectedPlanetIDs.contains($0.id) }

            // Calculate unique orbits
            let maxOrbit = planetOrbits.values.max() ?? 0
            let totalOrbits = max(maxOrbit + 1, 1)

            ZStack {
                // Central Sun
                ZStack {
                    // Sun glow layers
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow.opacity(0.4), .orange.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow, .orange],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .yellow.opacity(0.8), radius: 20)
                }
                .position(center)

                // Orbiting Planets
                ForEach(selectedPlanets, id: \.id) { planet in
                    if let orbitIndex = planetOrbits[planet.id] {
                        OrbitPlanetView(
                            planet: planet,
                            orbitIndex: orbitIndex,
                            totalOrbits: totalOrbits,
                            center: center,
                            maxRadius: maxRadius,
                            ringSpacing: ringSpacing,
                            reduceMotion: reduceMotion,
                            onOrbitChange: { newOrbit in
                                planetOrbits[planet.id] = newOrbit
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedPlanetIDs.count) Planet\(selectedPlanetIDs.count == 1 ? "" : "s") in Orbit")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Zoom: \(Int(zoomScale * 100))% • Pinch to zoom")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Button {
                    showingPlanetPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Manage")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(8)
                }
            }

            // Ring spacing control
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "circle.dotted")
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Ring Spacing")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(ringSpacing * 100))%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                }

                Slider(value: $ringSpacing, in: 0.5...2.0, step: 0.1)
                    .tint(.blue)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)

            // Quick stats
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    statPill(icon: "sparkles", label: "Total", value: "\(viewModel.totalPlanetsDiscovered)")
                    statPill(icon: "location.fill", label: "Distance", value: "\(Int(viewModel.totalDistanceTravelled / 1000))K km")

                    if let rarest = viewModel.rarestPlanet {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(rarest.rarity.color)
                                .font(.caption)
                            Text("Rarest: \(rarest.rarity.displayName)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
    }

    private func statPill(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - No Planet State

    private var noPlanetState: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.3))

            Text("No Planets Discovered")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Discover planets using the Generator tab to populate your galaxy!")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Stars Background

    private var starsBackground: some View {
        GeometryReader { geometry in
            ZStack {
                // Generate some random stars
                ForEach(0..<200, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.2...0.9)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
    }
}

// MARK: - Orbit Planet View

struct OrbitPlanetView: View {
    let planet: Planet
    let orbitIndex: Int
    let totalOrbits: Int
    let center: CGPoint
    let maxRadius: CGFloat
    let ringSpacing: CGFloat
    let reduceMotion: Bool
    let onOrbitChange: (Int) -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        TimelineView(.animation(paused: reduceMotion || isDragging)) { timeline in
            planetContent(time: timeline.date.timeIntervalSinceReferenceDate)
        }
    }

    // MARK: - Helper Methods

    private func planetContent(time: Double) -> some View {
        let orbitRadius = calculateOrbitRadius()
        let position = calculatePosition(time: time, orbitRadius: orbitRadius)
        let planetSize: CGFloat = 40 + CGFloat(orbitIndex) * 8

        return ZStack {
            // Orbit path
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                .position(center)

            // Planet with drag gesture
            PlanetView(planet: planet, size: planetSize)
                .position(position)
                .scaleEffect(isDragging ? 1.3 : 1.0)
                .animation(.spring(response: 0.3), value: isDragging)
                .gesture(radialDragGesture)
                .contextMenu {
                    contextMenuContent
                }
        }
    }

    private func calculateOrbitRadius() -> CGFloat {
        let baseRadius = maxRadius * (CGFloat(orbitIndex + 1) / CGFloat(max(totalOrbits, 1)))
        return baseRadius * ringSpacing * 0.85 + dragOffset
    }

    private func calculatePosition(time: Double, orbitRadius: CGFloat) -> CGPoint {
        let baseSpeed = 0.15
        let speedMultiplier = 1.5 - (Double(orbitIndex) / Double(max(totalOrbits - 1, 1))) * 0.8
        let orbitSpeed = baseSpeed * speedMultiplier
        let initialAngle = Double(planet.seed % 360) * (.pi / 180.0)
        let currentAngle = reduceMotion ? initialAngle : (time * orbitSpeed + initialAngle)

        let x = center.x + cos(currentAngle) * orbitRadius
        let y = center.y + sin(currentAngle) * orbitRadius
        return CGPoint(x: x, y: y)
    }

    private var radialDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true

                // Calculate radial distance from center
                let dx = value.location.x - center.x
                let dy = value.location.y - center.y
                let currentRadius = sqrt(dx * dx + dy * dy)

                // Calculate expected orbit radius
                let expectedRadius = maxRadius * (CGFloat(orbitIndex + 1) / CGFloat(max(totalOrbits, 1))) * ringSpacing * 0.85

                // Update offset
                dragOffset = currentRadius - expectedRadius
            }
            .onEnded { value in
                isDragging = false

                // Calculate which orbit this should snap to
                let dx = value.location.x - center.x
                let dy = value.location.y - center.y
                let finalRadius = sqrt(dx * dx + dy * dy)

                // Find closest orbit
                var closestOrbit = orbitIndex
                var minDistance = CGFloat.infinity

                for i in 0..<totalOrbits {
                    let orbitRadius = maxRadius * (CGFloat(i + 1) / CGFloat(max(totalOrbits, 1))) * ringSpacing * 0.85
                    let distance = abs(finalRadius - orbitRadius)

                    if distance < minDistance {
                        minDistance = distance
                        closestOrbit = i
                    }
                }

                // Only change orbit if dragged significantly
                if abs(closestOrbit - orbitIndex) > 0 {
                    onOrbitChange(closestOrbit)
                }

                dragOffset = 0
            }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        ForEach(0..<totalOrbits, id: \.self) { orbit in
            Button {
                onOrbitChange(orbit)
            } label: {
                HStack {
                    Text("Move to Ring \(orbit + 1)")
                    if orbit == orbitIndex {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}

// MARK: - Simple Planet Selection Sheet (for Galaxy View)

struct SimplePlanetSelectionSheet: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPlanetIDs: Set<UUID>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info banner
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Select up to 10 planets to display in orbit")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.2))

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.sortedPlanets) { planet in
                            SimplePlanetCard(
                                planet: planet,
                                isSelected: selectedPlanetIDs.contains(planet.id),
                                onToggle: {
                                    togglePlanetSelection(planet)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .background(Color.black)
            .navigationTitle("Manage Galaxy Planets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Clear All") {
                        selectedPlanetIDs.removeAll()
                    }
                    .foregroundStyle(.white)
                    .disabled(selectedPlanetIDs.isEmpty)
                }
            }
        }
    }

    private func togglePlanetSelection(_ planet: Planet) {
        if selectedPlanetIDs.contains(planet.id) {
            selectedPlanetIDs.remove(planet.id)
        } else if selectedPlanetIDs.count < 10 {
            selectedPlanetIDs.insert(planet.id)
        }
    }
}

// MARK: - Simple Planet Card

struct SimplePlanetCard: View {
    let planet: Planet
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    PlanetView(planet: planet, size: 100)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .background(Circle().fill(Color.black))
                            .font(.title2)
                            .padding(4)
                    }
                }

                VStack(spacing: 4) {
                    Text(planet.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(planet.rarity.displayName)
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(planet.rarity.color)
                        .cornerRadius(4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(isSelected ? 0.15 : 0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Planet Selection Card

struct PlanetSelectionCard: View {
    let planet: Planet
    let isSelected: Bool
    let isFavorited: Bool
    let onToggleSelection: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Button {
            onToggleSelection()
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    PlanetView(planet: planet, size: 100)

                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .background(Circle().fill(Color.black))
                            .font(.title2)
                            .padding(4)
                    }

                    // Favorite indicator
                    if isFavorited {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .background(Circle().fill(Color.black).padding(-4))
                            .font(.caption)
                            .padding(4)
                            .offset(x: -30, y: 0)
                    }
                }

                VStack(spacing: 4) {
                    Text(planet.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(planet.rarity.displayName)
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(planet.rarity.color)
                            .cornerRadius(4)

                        // Favorite toggle button
                        Button {
                            onToggleFavorite()
                        } label: {
                            Image(systemName: isFavorited ? "star.fill" : "star")
                                .foregroundStyle(isFavorited ? .yellow : .white.opacity(0.5))
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(isSelected ? 0.15 : 0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
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
