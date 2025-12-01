//
//  OzoneLayerView.swift
//  ClastPlanetsTesting
//
//  SwiftUI view for rendering an animated ozone layer effect on planets
//

import SwiftUI

/// An animated ozone layer overlay that creates a flowing, translucent mesh effect
/// on top of a planet. Uses Canvas for rendering and TimelineView for animation.
struct OzoneLayerView: View {
    let seed: Int
    let radius: CGFloat
    let density: Double // 0.0 to 1.0 - controls opacity/intensity

    // Accessibility: respect Reduce Motion setting
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        if density > 0.01 {
            if reduceMotion {
                // Static version when Reduce Motion is enabled
                Canvas { graphicsContext, size in
                    drawOzonePattern(
                        in: graphicsContext,
                        size: size,
                        phase: 0
                    )
                }
                .frame(width: radius * 2, height: radius * 2)
                .clipShape(Circle())
            } else {
                // Animated version
                TimelineView(.animation) { timelineContext in
                    // Calculate animation phase (very slow - full cycle every 40 seconds)
                    let phase = timelineContext.date.timeIntervalSinceReferenceDate / 40.0

                    Canvas { graphicsContext, size in
                        // Draw the ozone pattern
                        drawOzonePattern(
                            in: graphicsContext,
                            size: size,
                            phase: phase
                        )
                    }
                    .frame(width: radius * 2, height: radius * 2)
                    .clipShape(Circle()) // Clip to planet's circular shape
                }
            }
        }
    }

    // MARK: - Drawing

    /// Draws the ozone mesh pattern using multiple flowing bands with multiple density layers
    private func drawOzonePattern(in context: GraphicsContext, size: CGSize, phase: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Use seed to create variation between planets
        var rng = SeededRandomGenerator(seed: seed)

        // Draw multiple density layers for depth (2-3 layers)
        let layerCount = rng.nextInt(min: 2, max: 3)

        for layerIndex in 0..<layerCount {
            // Each layer has different depth and density
            let layerDepth = Double(layerIndex) / Double(layerCount)
            let layerDensity = 1.0 - (layerDepth * 0.4) // Deeper layers are slightly less dense
            let layerPhaseOffset = Double(layerIndex) * 2.0 // Different animation phases

            // Generate 4-7 flowing bands per layer (increased from 3-5 for thickness)
            let bandCount = rng.nextInt(min: 4, max: 7)

            for i in 0..<bandCount {
                // Each band has slightly different properties based on seed
                let bandSeed = Double(rng.nextInt(min: 0, max: 1000))
                let frequencyOffset = rng.nextDouble(min: 0, max: 2 * .pi)
                let amplitude = rng.nextDouble(min: 0.4, max: 0.8) // Increased amplitude for more movement
                let bandWidth = CGFloat(rng.nextDouble(min: 5, max: 12)) // Thicker bands

                // Create a flowing band path
                let path = createFlowingBand(
                    center: center,
                    radius: radius,
                    phase: phase * 1.5 + bandSeed + layerPhaseOffset, // Faster animation (1.5x speed)
                    frequencyOffset: frequencyOffset,
                    amplitude: amplitude,
                    bandIndex: i,
                    totalBands: bandCount,
                    layerDepth: layerDepth
                )

                // Draw the band with semi-transparent blue/green color
                // Color varies slightly based on seed and layer for variety
                let hue = 0.5 + rng.nextDouble(min: -0.1, max: 0.1) + (layerDepth * 0.05) // Blue-green range
                let saturation = 0.6 + (layerDepth * 0.2) // Deeper layers more saturated
                let color = Color(hue: hue, saturation: saturation, brightness: 0.8)

                // Opacity scales with density and varies per band and layer
                let baseOpacity = density * layerDensity * 0.25 * (1.0 - Double(i) / Double(bandCount) * 0.3)

                context.stroke(
                    path,
                    with: .color(color.opacity(baseOpacity)),
                    lineWidth: bandWidth
                )

                // Add a softer, wider version for glow effect
                context.stroke(
                    path,
                    with: .color(color.opacity(baseOpacity * 0.4)),
                    lineWidth: bandWidth * 2.5
                )

                // Add an even softer outer glow for depth
                context.stroke(
                    path,
                    with: .color(color.opacity(baseOpacity * 0.15)),
                    lineWidth: bandWidth * 4
                )
            }
        }

        // Add subtle sparkle/shimmer points that drift across the surface
        if density > 0.2 { // Lower threshold for more shimmer
            drawShimmerPoints(in: context, center: center, radius: radius, phase: phase, rng: &rng)
        }
    }

    /// Creates a flowing curved band that wraps around the planet
    private func createFlowingBand(
        center: CGPoint,
        radius: CGFloat,
        phase: Double,
        frequencyOffset: Double,
        amplitude: Double,
        bandIndex: Int,
        totalBands: Int,
        layerDepth: Double
    ) -> Path {
        var path = Path()

        // Number of points to create smooth curve
        let pointCount = 120

        for i in 0...pointCount {
            let t = Double(i) / Double(pointCount)
            let angle = t * 2 * .pi

            // Create wave pattern using multiple sin waves for organic look
            let wave1 = sin(angle * 3 + phase + frequencyOffset) * amplitude
            let wave2 = sin(angle * 5 - phase * 0.7 + frequencyOffset * 1.3) * amplitude * 0.5
            let wave3 = cos(angle * 2 + phase * 1.5) * amplitude * 0.3
            let wave4 = sin(angle * 7 + phase * 0.5) * amplitude * 0.25 // Additional wave for complexity

            // Combine waves and offset each band and layer
            let bandOffset = (Double(bandIndex) / Double(totalBands)) * 0.5 - 0.25
            let layerOffset = layerDepth * 0.15 // Separate layers radially
            let radiusMultiplier = 0.82 + wave1 + wave2 + wave3 + wave4 + bandOffset + layerOffset

            let distance = radius * radiusMultiplier
            let x = center.x + cos(angle) * distance
            let y = center.y + sin(angle) * distance

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }

    /// Draws small shimmer points that drift across the ozone layer
    private func drawShimmerPoints(
        in context: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        phase: Double,
        rng: inout SeededRandomGenerator
    ) {
        let shimmerCount = Int(density * 8) // More shimmers with higher density

        for _ in 0..<shimmerCount {
            // Each shimmer has a unique position and movement pattern
            let shimmerSeed = Double(rng.nextInt(min: 0, max: 1000))
            let angle = rng.nextDouble(min: 0, max: 2 * .pi)
            let distanceFactor = rng.nextDouble(min: 0.7, max: 0.95)

            // Shimmer drifts slowly around the planet
            let driftAngle = angle + phase * 0.3 + shimmerSeed
            let distance = radius * distanceFactor

            let x = center.x + cos(driftAngle) * distance
            let y = center.y + sin(driftAngle) * distance

            // Pulsating opacity for sparkle effect
            let pulsePhase = phase * 3 + shimmerSeed
            let opacity = (sin(pulsePhase) * 0.5 + 0.5) * density * 0.3

            // Draw shimmer as small circle
            let shimmerRadius: CGFloat = 2
            let shimmerPath = Circle()
                .path(in: CGRect(
                    x: x - shimmerRadius,
                    y: y - shimmerRadius,
                    width: shimmerRadius * 2,
                    height: shimmerRadius * 2
                ))

            context.fill(
                shimmerPath,
                with: .color(.white.opacity(opacity))
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Preview different densities
        ForEach([0.2, 0.5, 0.8], id: \.self) { density in
            ZStack {
                // Background planet
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue, .cyan],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Ozone layer on top
                OzoneLayerView(
                    seed: Int(density * 1000),
                    radius: 80,
                    density: density
                )
            }

            Text("Density: \(String(format: "%.1f", density))")
                .font(.caption)
        }
    }
    .padding()
    .background(Color.black)
}
