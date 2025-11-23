//
//  PlanetView.swift
//  ClastPlanetsTesting
//
//  SwiftUI view for rendering planets based on their traits
//

import SwiftUI

struct PlanetView: View {
    let planet: Planet
    var size: CGFloat = 200

    var body: some View {
        ZStack {
            // Atmosphere layer (outermost)
            atmosphereLayer

            // Rings (behind planet)
            if planet.ringType != .none {
                ringsLayer
                    .rotationEffect(.degrees(30)) // Tilt rings for perspective
            }

            // Planet body
            planetBody

            // Ozone layer (on top of planet surface)
            OzoneLayerView(
                seed: planet.seed,
                radius: planetRadius,
                density: planet.ozoneDensity
            )

            // Moons
            if planet.moonCount > 0 {
                moonsLayer
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Planet Body

    private var planetBody: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [planet.primaryColor, planet.secondaryColor],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: planetRadius
                    )
                )
                .frame(width: planetRadius * 2, height: planetRadius * 2)

            // Add patterns based on base type
            baseTypePattern
        }
    }

    // MARK: - Base Type Patterns

    @ViewBuilder
    private var baseTypePattern: some View {
        switch planet.baseType {
        case .solid:
            // Clean, simple planet
            EmptyView()

        case .striped:
            // Horizontal stripes
            VStack(spacing: planetRadius / 8) {
                ForEach(0..<5) { _ in
                    Rectangle()
                        .fill(planet.accentColor.opacity(0.3))
                        .frame(height: planetRadius / 10)
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .cratered:
            // Small craters (circles)
            ZStack {
                ForEach(0..<8) { index in
                    Circle()
                        .fill(planet.secondaryColor.opacity(0.5))
                        .frame(width: planetRadius / 5, height: planetRadius / 5)
                        .offset(craterOffset(index: index))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .swirled:
            // Swirl effect using angular gradient
            Circle()
                .fill(
                    AngularGradient(
                        colors: [planet.primaryColor, planet.accentColor, planet.secondaryColor, planet.primaryColor],
                        center: .center
                    )
                )
                .frame(width: planetRadius * 2, height: planetRadius * 2)
                .opacity(0.6)

        case .volcanic:
            // Glowing spots
            ZStack {
                ForEach(0..<6) { index in
                    Circle()
                        .fill(Color.orange.opacity(0.8))
                        .frame(width: planetRadius / 4, height: planetRadius / 4)
                        .blur(radius: 5)
                        .offset(volcanoOffset(index: index))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())
        }
    }

    // MARK: - Atmosphere Layer

    @ViewBuilder
    private var atmosphereLayer: some View {
        switch planet.atmosphereType {
        case .none:
            EmptyView()

        case .glow:
            // Simple glow around planet
            Circle()
                .fill(
                    RadialGradient(
                        colors: [planet.primaryColor.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: planetRadius * 0.9,
                        endRadius: planetRadius * 1.3
                    )
                )
                .frame(width: planetRadius * 2.6, height: planetRadius * 2.6)

        case .halo:
            // Brighter, more defined halo
            Circle()
                .stroke(planet.accentColor.opacity(0.5), lineWidth: 3)
                .frame(width: planetRadius * 2.4, height: planetRadius * 2.4)
                .blur(radius: 4)

        case .aurora:
            // Multiple colored rings
            ZStack {
                Circle()
                    .stroke(planet.primaryColor.opacity(0.4), lineWidth: 2)
                    .frame(width: planetRadius * 2.3, height: planetRadius * 2.3)
                    .blur(radius: 3)

                Circle()
                    .stroke(planet.accentColor.opacity(0.4), lineWidth: 2)
                    .frame(width: planetRadius * 2.5, height: planetRadius * 2.5)
                    .blur(radius: 3)
            }

        case .cosmic:
            // Dramatic multi-layer glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [planet.accentColor.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: planetRadius,
                            endRadius: planetRadius * 1.5
                        )
                    )
                    .frame(width: planetRadius * 3, height: planetRadius * 3)

                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    .frame(width: planetRadius * 2.6, height: planetRadius * 2.6)
                    .blur(radius: 5)
            }
        }
    }

    // MARK: - Rings Layer

    @ViewBuilder
    private var ringsLayer: some View {
        switch planet.ringType {
        case .none:
            EmptyView()

        case .simple:
            // Single ring
            Ellipse()
                .stroke(planet.accentColor.opacity(0.6), lineWidth: 4)
                .frame(width: planetRadius * 2.8, height: planetRadius * 0.8)

        case .double:
            // Two rings
            ZStack {
                Ellipse()
                    .stroke(planet.accentColor.opacity(0.6), lineWidth: 4)
                    .frame(width: planetRadius * 2.8, height: planetRadius * 0.8)

                Ellipse()
                    .stroke(planet.secondaryColor.opacity(0.5), lineWidth: 3)
                    .frame(width: planetRadius * 3.2, height: planetRadius * 1.0)
            }

        case .chunky:
            // Thicker, more prominent rings
            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [planet.accentColor.opacity(0.7), planet.secondaryColor.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: planetRadius * 3.0, height: planetRadius * 0.6)

                Ellipse()
                    .stroke(planet.accentColor, lineWidth: 2)
                    .frame(width: planetRadius * 3.0, height: planetRadius * 0.6)
            }

        case .rainbow:
            // Multiple colorful rings
            ZStack {
                ForEach(0..<4) { index in
                    Ellipse()
                        .stroke(rainbowColor(index: index).opacity(0.6), lineWidth: 2)
                        .frame(
                            width: planetRadius * (2.6 + Double(index) * 0.2),
                            height: planetRadius * (0.6 + Double(index) * 0.1)
                        )
                }
            }
        }
    }

    // MARK: - Moons Layer

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @ViewBuilder
    private var moonsLayer: some View {
        if reduceMotion {
            // Static moons when Reduce Motion is enabled
            moonsContent(rotationAngle: 0)
        } else {
            // Animated orbiting moons
            TimelineView(.animation) { timelineContext in
                moonsContent(rotationAngle: timelineContext.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    /// Renders the moons at a given rotation angle
    private func moonsContent(rotationAngle: Double) -> some View {
        ZStack {
            ForEach(0..<planet.moonCount, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.5)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: moonRadius
                        )
                    )
                    .frame(width: moonRadius * 2, height: moonRadius * 2)
                    .offset(moonOffset(index: index, rotationAngle: rotationAngle))
            }
        }
    }

    // MARK: - Helper Computed Properties

    private var planetRadius: CGFloat {
        (size / 2) * planet.size * 0.6 // Scale to fit with room for rings/moons
    }

    private var moonRadius: CGFloat {
        planetRadius * 0.15
    }

    // MARK: - Positioning Helpers

    /// Calculate offset for moons based on index and current rotation angle
    private func moonOffset(index: Int, rotationAngle: Double) -> CGSize {
        // Use planet seed to make moon positions deterministic
        var rng = SeededRandomGenerator(seed: planet.seed + index * 1000)

        // Each moon has a unique orbital speed and starting angle
        let baseAngle = rng.nextDouble() * 2 * .pi
        let orbitalSpeed = rng.nextDouble(min: 0.1, max: 0.3) // Radians per second
        let distance = planetRadius * rng.nextDouble(min: 1.4, max: 1.8)

        // Calculate current angle based on rotation and orbital speed
        // Outer moons (higher index) orbit slower, creating varied motion
        let speedMultiplier = 1.0 - (Double(index) * 0.2)
        let currentAngle = baseAngle + (rotationAngle * orbitalSpeed * speedMultiplier)

        return CGSize(
            width: cos(currentAngle) * distance,
            height: sin(currentAngle) * distance
        )
    }

    /// Calculate offset for craters based on index
    private func craterOffset(index: Int) -> CGSize {
        var rng = SeededRandomGenerator(seed: planet.seed + index * 500)

        let angle = rng.nextDouble() * 2 * .pi
        let distance = planetRadius * rng.nextDouble(min: 0.3, max: 0.7)

        return CGSize(
            width: cos(angle) * distance,
            height: sin(angle) * distance
        )
    }

    /// Calculate offset for volcanic spots based on index
    private func volcanoOffset(index: Int) -> CGSize {
        var rng = SeededRandomGenerator(seed: planet.seed + index * 700)

        let angle = rng.nextDouble() * 2 * .pi
        let distance = planetRadius * rng.nextDouble(min: 0.2, max: 0.6)

        return CGSize(
            width: cos(angle) * distance,
            height: sin(angle) * distance
        )
    }

    /// Get rainbow color for ring index
    private func rainbowColor(index: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        return colors[index % colors.count]
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        // Generate a few sample planets
        ForEach(0..<3) { index in
            let planet = PlanetGenerator.generatePlanet(
                atDistance: Double(index * 30000),
                seed: index * 100
            )

            VStack {
                PlanetView(planet: planet, size: 150)

                Text(planet.name)
                    .font(.caption)

                Text(planet.rarity.displayName)
                    .font(.caption2)
                    .foregroundStyle(planet.rarity.color)
            }
        }
    }
    .padding()
}
