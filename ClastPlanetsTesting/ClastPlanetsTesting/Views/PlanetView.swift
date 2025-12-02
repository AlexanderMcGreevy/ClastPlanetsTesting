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
    var animated: Bool = true

    var body: some View {
        ZStack {
            // Atmosphere layer (outermost)
            atmosphereLayer

            // Back rings (behind planet)
            if planet.ringType != .none {
                if planet.ringType == .crossed {
                    // Crossed rings: two sets at different angles
                    backRingsLayer
                        .rotationEffect(.degrees(planet.ringTilt))
                    backRingsLayer
                        .rotationEffect(.degrees(planet.ringTilt + 90))
                } else {
                    backRingsLayer
                        .rotationEffect(.degrees(planet.ringTilt))
                }
            }

            // Planet body
            planetBody

            // Ozone layer (on top of planet surface)
            OzoneLayerView(
                seed: planet.seed,
                radius: planetRadius,
                density: planet.ozoneDensity
            )

            // Front rings (in front of planet)
            if planet.ringType != .none {
                if planet.ringType == .crossed {
                    // Crossed rings: two sets at different angles
                    frontRingsLayer
                        .rotationEffect(.degrees(planet.ringTilt))
                    frontRingsLayer
                        .rotationEffect(.degrees(planet.ringTilt + 90))
                } else {
                    frontRingsLayer
                        .rotationEffect(.degrees(planet.ringTilt))
                }
            }

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

            // Add surface texture patterns
            surfacePattern

            // Add patterns based on base type
            baseTypePattern
        }
    }

    // MARK: - Surface Texture Patterns

    @ViewBuilder
    private var surfacePattern: some View {
        switch planet.surfaceType {
        case .smooth:
            // Clean, no texture
            EmptyView()

        case .rocky:
            // Small rocks scattered across surface
            ZStack {
                ForEach(0..<15) { index in
                    Circle()
                        .fill(planet.secondaryColor.opacity(0.25))
                        .frame(width: planetRadius / 12, height: planetRadius / 12)
                        .offset(craterOffset(index: index + 100))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .icy:
            // Crystalline frost patterns
            ZStack {
                ForEach(0..<10) { index in
                    Diamond()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        .frame(width: planetRadius / 6, height: planetRadius / 6)
                        .rotationEffect(.degrees(Double(index) * 36))
                        .offset(craterOffset(index: index + 200))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .desert:
            // Sandy dune waves
            VStack(spacing: planetRadius / 12) {
                ForEach(0..<6) { _ in
                    Rectangle()
                        .fill(planet.accentColor.opacity(0.15))
                        .frame(height: planetRadius / 15)
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .oceanic:
            // Water wave ripples
            ZStack {
                ForEach(0..<4) { index in
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: planetRadius * (0.5 + Double(index) * 0.3), height: planetRadius * (0.5 + Double(index) * 0.3))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .volcanic:
            // Lava cracks/veins
            ZStack {
                ForEach(0..<8) { index in
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 2, height: planetRadius * 0.8)
                        .rotationEffect(.degrees(Double(index) * 45))
                        .offset(volcanoOffset(index: index + 50))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .crystalline:
            // Large geometric crystals
            ZStack {
                ForEach(0..<8) { index in
                    Diamond()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), planet.accentColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: planetRadius / 4, height: planetRadius / 4)
                        .rotationEffect(.degrees(Double(index) * 45))
                        .offset(craterOffset(index: index + 300))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .molten:
            // Flowing lava texture
            ZStack {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange.opacity(0.4), Color.red.opacity(0.2)],
                                center: .center,
                                startRadius: 0,
                                endRadius: planetRadius / 3
                            )
                        )
                        .frame(width: planetRadius / 2, height: planetRadius / 2)
                        .blur(radius: 4)
                        .offset(volcanoOffset(index: index + 150))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .prismatic:
            // Iridescent rainbow shimmer
            Circle()
                .fill(
                    AngularGradient(
                        colors: [.red.opacity(0.3), .orange.opacity(0.3), .yellow.opacity(0.3), .green.opacity(0.3), .cyan.opacity(0.3), .blue.opacity(0.3), .purple.opacity(0.3), .red.opacity(0.3)],
                        center: .center
                    )
                )
                .frame(width: planetRadius * 2, height: planetRadius * 2)
                .blur(radius: 3)

        case .voidlike:
            // Deep dark with star particles
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: planetRadius * 2, height: planetRadius * 2)

                ForEach(0..<12) { index in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: planetRadius / 20, height: planetRadius / 20)
                        .offset(craterOffset(index: index + 400))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())
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

        case .crystalline:
            // Geometric faceted appearance with sharp edges
            ZStack {
                ForEach(0..<12) { index in
                    Diamond()
                        .fill(planet.accentColor.opacity(0.4))
                        .frame(width: planetRadius / 3, height: planetRadius / 3)
                        .rotationEffect(.degrees(Double(index) * 30))
                        .offset(craterOffset(index: index))
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .nebulous:
            // Cloudy, ethereal gas effect with multiple layers
            ZStack {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [planet.primaryColor.opacity(0.6), planet.secondaryColor.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: planetRadius * 0.8
                            )
                        )
                        .frame(width: planetRadius * 1.5, height: planetRadius * 1.5)
                        .offset(craterOffset(index: index * 2))
                        .blur(radius: 8)
                }
            }
            .frame(width: planetRadius * 2, height: planetRadius * 2)
            .clipShape(Circle())

        case .prismatic:
            // Rainbow refraction effect
            Circle()
                .fill(
                    AngularGradient(
                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red],
                        center: .center
                    )
                )
                .frame(width: planetRadius * 2, height: planetRadius * 2)
                .opacity(0.7)
                .blur(radius: 2)
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

        case .storm:
            // Turbulent swirling storm effect
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [planet.primaryColor.opacity(0.6), planet.secondaryColor.opacity(0.4), Color.clear, planet.accentColor.opacity(0.5)],
                                center: .center
                            ),
                            lineWidth: 4
                        )
                        .frame(width: planetRadius * (2.3 + Double(index) * 0.2), height: planetRadius * (2.3 + Double(index) * 0.2))
                        .rotationEffect(.degrees(Double(index) * 45))
                        .blur(radius: 6)
                }
            }

        case .ethereal:
            // Ghostly, translucent shimmer
            ZStack {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.3), planet.primaryColor.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: planetRadius * 0.8,
                                endRadius: planetRadius * (1.3 + Double(index) * 0.15)
                            )
                        )
                        .frame(width: planetRadius * (2.6 + Double(index) * 0.3), height: planetRadius * (2.6 + Double(index) * 0.3))
                        .opacity(0.7 - Double(index) * 0.15)
                        .blur(radius: 10)
                }
            }
        }
    }

    // MARK: - Back Rings Layer (behind planet)

    @ViewBuilder
    private var backRingsLayer: some View {
        backRingsContent
    }

    // MARK: - Front Rings Layer (in front of planet)

    @ViewBuilder
    private var frontRingsLayer: some View {
        frontRingsContent
    }

    // MARK: - Back Rings Content (bottom arc)

    @ViewBuilder
    private var backRingsContent: some View {
        switch planet.ringType {
        case .none:
            EmptyView()

        case .simple:
            RingArc(
                width: planetRadius * 2.8,
                height: planetRadius * 0.8,
                color: planet.accentColor.opacity(0.6),
                lineWidth: 4 * planet.ringWidth,
                startAngle: .degrees(0),
                endAngle: .degrees(180)
            )

        case .double:
            ZStack {
                RingArc(
                    width: planetRadius * 2.8,
                    height: planetRadius * 0.8,
                    color: planet.accentColor.opacity(0.6),
                    lineWidth: 4 * planet.ringWidth,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180)
                )
                RingArc(
                    width: planetRadius * 3.2,
                    height: planetRadius * 1.0,
                    color: planet.secondaryColor.opacity(0.5),
                    lineWidth: 3 * planet.ringWidth,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180)
                )
            }

        case .chunky:
            ZStack {
                RingArc(
                    width: planetRadius * 3.0,
                    height: planetRadius * 0.6,
                    gradient: LinearGradient(
                        colors: [planet.accentColor.opacity(0.7), planet.secondaryColor.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 12 * planet.ringWidth,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180)
                )
                RingArc(
                    width: planetRadius * 3.0,
                    height: planetRadius * 0.6,
                    color: planet.accentColor,
                    lineWidth: 2 * planet.ringWidth,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180)
                )
            }

        case .rainbow:
            ZStack {
                ForEach(0..<4) { index in
                    RingArc(
                        width: planetRadius * (2.6 + Double(index) * 0.2),
                        height: planetRadius * (0.6 + Double(index) * 0.1),
                        color: rainbowColor(index: index).opacity(0.6),
                        lineWidth: 2 * planet.ringWidth,
                        startAngle: .degrees(0),
                        endAngle: .degrees(180)
                    )
                }
            }

        case .crossed:
            // Crossed rings rendered same as simple but drawn at two angles (handled in body)
            RingArc(
                width: planetRadius * 2.8,
                height: planetRadius * 0.8,
                color: planet.accentColor.opacity(0.6),
                lineWidth: 4 * planet.ringWidth,
                startAngle: .degrees(0),
                endAngle: .degrees(180)
            )
        }
    }

    // MARK: - Front Rings Content (top arc)

    @ViewBuilder
    private var frontRingsContent: some View {
        switch planet.ringType {
        case .none:
            EmptyView()

        case .simple:
            RingArc(
                width: planetRadius * 2.8,
                height: planetRadius * 0.8,
                color: planet.accentColor.opacity(0.6),
                lineWidth: 4 * planet.ringWidth,
                startAngle: .degrees(180),
                endAngle: .degrees(360)
            )

        case .double:
            ZStack {
                RingArc(
                    width: planetRadius * 2.8,
                    height: planetRadius * 0.8,
                    color: planet.accentColor.opacity(0.6),
                    lineWidth: 4 * planet.ringWidth,
                    startAngle: .degrees(180),
                    endAngle: .degrees(360)
                )
                RingArc(
                    width: planetRadius * 3.2,
                    height: planetRadius * 1.0,
                    color: planet.secondaryColor.opacity(0.5),
                    lineWidth: 3 * planet.ringWidth,
                    startAngle: .degrees(180),
                    endAngle: .degrees(360)
                )
            }

        case .chunky:
            ZStack {
                RingArc(
                    width: planetRadius * 3.0,
                    height: planetRadius * 0.6,
                    gradient: LinearGradient(
                        colors: [planet.accentColor.opacity(0.7), planet.secondaryColor.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 12 * planet.ringWidth,
                    startAngle: .degrees(180),
                    endAngle: .degrees(360)
                )
                RingArc(
                    width: planetRadius * 3.0,
                    height: planetRadius * 0.6,
                    color: planet.accentColor,
                    lineWidth: 2 * planet.ringWidth,
                    startAngle: .degrees(180),
                    endAngle: .degrees(360)
                )
            }

        case .rainbow:
            ZStack {
                ForEach(0..<4) { index in
                    RingArc(
                        width: planetRadius * (2.6 + Double(index) * 0.2),
                        height: planetRadius * (0.6 + Double(index) * 0.1),
                        color: rainbowColor(index: index).opacity(0.6),
                        lineWidth: 2 * planet.ringWidth,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360)
                    )
                }
            }

        case .crossed:
            // Crossed rings rendered same as simple but drawn at two angles (handled in body)
            RingArc(
                width: planetRadius * 2.8,
                height: planetRadius * 0.8,
                color: planet.accentColor.opacity(0.6),
                lineWidth: 4 * planet.ringWidth,
                startAngle: .degrees(180),
                endAngle: .degrees(360)
            )
        }
    }

    // MARK: - Moons Layer

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @ViewBuilder
    private var moonsLayer: some View {
        if reduceMotion || !animated {
            // Static moons when Reduce Motion is enabled or animation is disabled
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

// MARK: - Diamond Shape

/// Custom diamond shape for crystalline planets
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfWidth = rect.width / 2
        let halfHeight = rect.height / 2

        // Top point
        path.move(to: CGPoint(x: center.x, y: center.y - halfHeight))
        // Right point
        path.addLine(to: CGPoint(x: center.x + halfWidth, y: center.y))
        // Bottom point
        path.addLine(to: CGPoint(x: center.x, y: center.y + halfHeight))
        // Left point
        path.addLine(to: CGPoint(x: center.x - halfWidth, y: center.y))
        // Close path
        path.closeSubpath()

        return path
    }
}

// MARK: - Ring Arc Shape

/// Custom shape for drawing elliptical arcs (for planet rings)
struct RingArcShape: Shape {
    let width: CGFloat
    let height: CGFloat
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radiusX = width / 2
        let radiusY = height / 2

        // Generate points along the elliptical arc
        let startRadians = startAngle.radians
        let endRadians = endAngle.radians

        // Determine if we need to wrap around (e.g., 270° to 90°)
        var currentAngle = startRadians
        let angleIncrement = 0.01 // Small increment for smooth arc

        // Move to starting point
        let startX = center.x + cos(currentAngle) * radiusX
        let startY = center.y + sin(currentAngle) * radiusY
        path.move(to: CGPoint(x: startX, y: startY))

        // Draw arc
        while currentAngle < endRadians {
            currentAngle += angleIncrement
            if currentAngle > endRadians {
                currentAngle = endRadians
            }

            let x = center.x + cos(currentAngle) * radiusX
            let y = center.y + sin(currentAngle) * radiusY
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

/// View wrapper for RingArc that supports both colors and gradients
struct RingArc: View {
    let width: CGFloat
    let height: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    let lineWidth: CGFloat

    // Support either color or gradient
    var color: Color?
    var gradient: LinearGradient?

    init(width: CGFloat, height: CGFloat, color: Color, lineWidth: CGFloat, startAngle: Angle, endAngle: Angle) {
        self.width = width
        self.height = height
        self.color = color
        self.gradient = nil
        self.lineWidth = lineWidth
        self.startAngle = startAngle
        self.endAngle = endAngle
    }

    init(width: CGFloat, height: CGFloat, gradient: LinearGradient, lineWidth: CGFloat, startAngle: Angle, endAngle: Angle) {
        self.width = width
        self.height = height
        self.color = nil
        self.gradient = gradient
        self.lineWidth = lineWidth
        self.startAngle = startAngle
        self.endAngle = endAngle
    }

    var body: some View {
        if let gradient = gradient {
            RingArcShape(
                width: width,
                height: height,
                startAngle: startAngle,
                endAngle: endAngle
            )
            .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: width, height: height)
        } else {
            RingArcShape(
                width: width,
                height: height,
                startAngle: startAngle,
                endAngle: endAngle
            )
            .stroke(color ?? .clear, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: width, height: height)
        }
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
