//
//  PlanetGenerator.swift
//  ClastPlanetsTesting
//
//  Handles procedural generation of planets based on distance traveled
//

import Foundation

class PlanetGenerator {

    // MARK: - Planet Name Generation

    private static let prefixes = [
        "Astra", "Celestia", "Nova", "Nebula", "Zenith", "Cosmos", "Stellar",
        "Luna", "Sol", "Orbit", "Galax", "Helio", "Astro", "Vega", "Polaris"
    ]

    private static let suffixes = [
        "prime", "major", "minor", "alpha", "beta", "gamma", "delta",
        "one", "two", "nexus", "core", "haven", "reach", "point"
    ]

    // MARK: - Color Generation (Random)

    // MARK: - Main Generation Function

    /// Generate a planet based on the total distance traveled
    /// - Parameters:
    ///   - distance: Total distance traveled (0-100,000)
    ///   - seed: Random seed for deterministic generation
    /// - Returns: A procedurally generated Planet
    static func generatePlanet(atDistance distance: Double, seed: Int? = nil) -> Planet {
        let actualSeed = seed ?? Int.random(in: 0...Int.max)
        var rng = SeededRandomGenerator(seed: actualSeed)

        // Calculate rarity probabilities based on distance
        let rarity = determineRarity(distance: distance, rng: &rng)

        // Generate components based on rarity
        let baseType = generateBaseType(rarity: rarity, rng: &rng)
        let surfaceType = generateSurfaceType(rarity: rarity, rng: &rng)
        let ringType = generateRingType(rarity: rarity, rng: &rng)
        let moonCount = generateMoonCount(rarity: rarity, rng: &rng)
        let atmosphereType = generateAtmosphereType(rarity: rarity, rng: &rng)
        let sizeClass = generateSizeClass(rarity: rarity, rng: &rng)
        let size = rng.nextDouble(min: sizeClass.sizeRange.min, max: sizeClass.sizeRange.max)
        let ozoneDensity = generateOzoneDensity(rarity: rarity, rng: &rng)

        // Generate ring properties
        let ringTilt = rng.nextDouble(min: 0, max: 360)
        let ringWidth = rng.nextDouble(min: 0.5, max: 2.0)

        // Generate random colors
        let colors = generateRandomColors(rng: &rng)

        // Generate name
        let name = generateName(rng: &rng)

        return Planet(
            id: UUID(),
            name: name,
            distanceDiscoveredAt: distance,
            rarity: rarity,
            seed: actualSeed,
            baseType: baseType,
            surfaceType: surfaceType,
            ringType: ringType,
            moonCount: moonCount,
            atmosphereType: atmosphereType,
            sizeClass: sizeClass,
            size: size,
            ozoneDensity: ozoneDensity,
            ringTilt: ringTilt,
            ringWidth: ringWidth,
            primaryColorHex: colors.primary,
            secondaryColorHex: colors.secondary,
            accentColorHex: colors.accent
        )
    }

    // MARK: - Rarity Determination

    /// Determine planet rarity based on distance
    /// Distance near 0 → mostly common
    /// Mid-range → mix of common/uncommon/rare
    /// High distance → better chance of rare/legendary/mythic
    private static func determineRarity(distance: Double, rng: inout SeededRandomGenerator) -> Rarity {
        // Normalize distance to 0-1 scale (assuming max distance of 100,000)
        let normalizedDistance = min(distance / 100_000, 1.0)

        let roll = rng.nextDouble()

        // Distance progression:
        // 0-20,000: Mostly common
        // 20,000-50,000: Common → Uncommon
        // 50,000-80,000: Uncommon → Rare
        // 80,000-95,000: Rare → Legendary
        // 95,000+: Legendary → Mythic (very rare)

        if normalizedDistance < 0.2 {
            // Early game: 80% common, 18% uncommon, 2% rare
            if roll < 0.80 { return .common }
            if roll < 0.98 { return .uncommon }
            return .rare
        } else if normalizedDistance < 0.5 {
            // Mid-early: 50% common, 35% uncommon, 13% rare, 2% legendary
            if roll < 0.50 { return .common }
            if roll < 0.85 { return .uncommon }
            if roll < 0.98 { return .rare }
            return .legendary
        } else if normalizedDistance < 0.8 {
            // Mid-late: 20% common, 40% uncommon, 35% rare, 5% legendary
            if roll < 0.20 { return .common }
            if roll < 0.60 { return .uncommon }
            if roll < 0.95 { return .rare }
            return .legendary
        } else if normalizedDistance < 0.95 {
            // Late game: 5% common, 20% uncommon, 50% rare, 24% legendary, 1% mythic
            if roll < 0.05 { return .common }
            if roll < 0.25 { return .uncommon }
            if roll < 0.75 { return .rare }
            if roll < 0.99 { return .legendary }
            return .mythic
        } else {
            // End game: 2% common, 10% uncommon, 30% rare, 55% legendary, 3% mythic
            if roll < 0.02 { return .common }
            if roll < 0.12 { return .uncommon }
            if roll < 0.42 { return .rare }
            if roll < 0.97 { return .legendary }
            return .mythic
        }
    }

    // MARK: - Component Generation

    private static func generateBaseType(rarity: Rarity, rng: inout SeededRandomGenerator) -> BaseType {
        let roll = rng.nextDouble()

        // Use the overall planet rarity to influence trait probabilities
        switch rarity {
        case .common:
            // Early game: 70% common, 25% uncommon, 5% rare
            if roll < 0.70 { return .solid }
            if roll < 0.95 { return [.striped, .cratered].randomElement(using: &rng)! }
            return .swirled
        case .uncommon:
            // 40% common, 40% uncommon, 15% rare, 5% legendary
            if roll < 0.40 { return .solid }
            if roll < 0.80 { return [.striped, .cratered].randomElement(using: &rng)! }
            if roll < 0.95 { return .swirled }
            return .volcanic
        case .rare:
            // 10% common, 30% uncommon, 50% rare, 10% legendary
            if roll < 0.10 { return .solid }
            if roll < 0.40 { return [.striped, .cratered].randomElement(using: &rng)! }
            if roll < 0.90 { return .swirled }
            return .volcanic
        case .legendary:
            // 1% common, 10% uncommon, 30% rare, 50% legendary, 9% mythic
            if roll < 0.01 { return .solid }
            if roll < 0.11 { return [.striped, .cratered].randomElement(using: &rng)! }
            if roll < 0.41 { return .swirled }
            if roll < 0.91 { return .volcanic }
            return [.crystalline, .nebulous, .prismatic].randomElement(using: &rng)!
        case .mythic:
            // 1% common, 5% uncommon, 15% rare, 30% legendary, 49% mythic
            if roll < 0.01 { return .solid }
            if roll < 0.06 { return [.striped, .cratered].randomElement(using: &rng)! }
            if roll < 0.21 { return .swirled }
            if roll < 0.51 { return .volcanic }
            return [.crystalline, .nebulous, .prismatic].randomElement(using: &rng)!
        }
    }

    private static func generateSurfaceType(rarity: Rarity, rng: inout SeededRandomGenerator) -> SurfaceType {
        let roll = rng.nextDouble()

        switch rarity {
        case .common:
            // Early game: 75% common, 23% uncommon, 2% rare
            if roll < 0.75 { return [.smooth, .rocky].randomElement(using: &rng)! }
            if roll < 0.98 { return [.desert, .icy].randomElement(using: &rng)! }
            return [.oceanic, .volcanic].randomElement(using: &rng)!
        case .uncommon:
            // 40% common, 45% uncommon, 13% rare, 2% legendary
            if roll < 0.40 { return [.smooth, .rocky].randomElement(using: &rng)! }
            if roll < 0.85 { return [.desert, .icy].randomElement(using: &rng)! }
            if roll < 0.98 { return [.oceanic, .volcanic].randomElement(using: &rng)! }
            return [.crystalline, .molten].randomElement(using: &rng)!
        case .rare:
            // 10% common, 30% uncommon, 50% rare, 9% legendary, 1% mythic
            if roll < 0.10 { return [.smooth, .rocky].randomElement(using: &rng)! }
            if roll < 0.40 { return [.desert, .icy].randomElement(using: &rng)! }
            if roll < 0.90 { return [.oceanic, .volcanic].randomElement(using: &rng)! }
            if roll < 0.99 { return [.crystalline, .molten].randomElement(using: &rng)! }
            return [.prismatic, .voidlike].randomElement(using: &rng)!
        case .legendary:
            // 1% common, 10% uncommon, 30% rare, 50% legendary, 9% mythic
            if roll < 0.01 { return [.smooth, .rocky].randomElement(using: &rng)! }
            if roll < 0.11 { return [.desert, .icy].randomElement(using: &rng)! }
            if roll < 0.41 { return [.oceanic, .volcanic].randomElement(using: &rng)! }
            if roll < 0.91 { return [.crystalline, .molten].randomElement(using: &rng)! }
            return [.prismatic, .voidlike].randomElement(using: &rng)!
        case .mythic:
            // 1% common, 5% uncommon, 15% rare, 30% legendary, 49% mythic
            if roll < 0.01 { return [.smooth, .rocky].randomElement(using: &rng)! }
            if roll < 0.06 { return [.desert, .icy].randomElement(using: &rng)! }
            if roll < 0.21 { return [.oceanic, .volcanic].randomElement(using: &rng)! }
            if roll < 0.51 { return [.crystalline, .molten].randomElement(using: &rng)! }
            return [.prismatic, .voidlike].randomElement(using: &rng)!
        }
    }

    private static func generateRingType(rarity: Rarity, rng: inout SeededRandomGenerator) -> RingType {
        let roll = rng.nextDouble()

        switch rarity {
        case .common:
            // Early: 70% none, 28% simple, 2% double
            if roll < 0.70 { return .none }
            if roll < 0.98 { return .simple }
            return .double
        case .uncommon:
            // 50% none, 35% simple, 12% double, 3% chunky
            if roll < 0.50 { return .none }
            if roll < 0.85 { return .simple }
            if roll < 0.97 { return .double }
            return .chunky
        case .rare:
            // 30% none, 25% simple, 30% double, 14% chunky, 1% rainbow
            if roll < 0.30 { return .none }
            if roll < 0.55 { return .simple }
            if roll < 0.85 { return .double }
            if roll < 0.99 { return .chunky }
            return .rainbow
        case .legendary:
            // 10% none, 15% simple, 25% double, 40% chunky, 9% rainbow, 1% crossed
            if roll < 0.10 { return .none }
            if roll < 0.25 { return .simple }
            if roll < 0.50 { return .double }
            if roll < 0.90 { return .chunky }
            if roll < 0.99 { return .rainbow }
            return .crossed
        case .mythic:
            // 5% none, 10% simple, 15% double, 25% chunky, 35% rainbow, 10% crossed
            if roll < 0.05 { return .none }
            if roll < 0.15 { return .simple }
            if roll < 0.30 { return .double }
            if roll < 0.55 { return .chunky }
            if roll < 0.90 { return .rainbow }
            return .crossed
        }
    }

    private static func generateMoonCount(rarity: Rarity, rng: inout SeededRandomGenerator) -> Int {
        let roll = rng.nextDouble()

        switch rarity {
        case .common:
            // Early: 70% 0, 25% 1, 5% 2
            if roll < 0.70 { return 0 }
            if roll < 0.95 { return 1 }
            return 2
        case .uncommon:
            // 40% 0, 40% 1, 18% 2, 2% 3
            if roll < 0.40 { return 0 }
            if roll < 0.80 { return 1 }
            if roll < 0.98 { return 2 }
            return 3
        case .rare:
            // 20% 0, 35% 1, 35% 2, 10% 3
            if roll < 0.20 { return 0 }
            if roll < 0.55 { return 1 }
            if roll < 0.90 { return 2 }
            return 3
        case .legendary:
            // 5% 0, 20% 1, 45% 2, 30% 3
            if roll < 0.05 { return 0 }
            if roll < 0.25 { return 1 }
            if roll < 0.70 { return 2 }
            return 3
        case .mythic:
            // 1% 0, 10% 1, 40% 2, 49% 3
            if roll < 0.01 { return 0 }
            if roll < 0.11 { return 1 }
            if roll < 0.51 { return 2 }
            return 3
        }
    }

    private static func generateAtmosphereType(rarity: Rarity, rng: inout SeededRandomGenerator) -> AtmosphereType {
        let roll = rng.nextDouble()

        switch rarity {
        case .common:
            // Early: 60% none, 37% glow, 3% halo
            if roll < 0.60 { return .none }
            if roll < 0.97 { return .glow }
            return .halo
        case .uncommon:
            // 40% none, 45% glow, 13% halo, 2% aurora
            if roll < 0.40 { return .none }
            if roll < 0.85 { return .glow }
            if roll < 0.98 { return .halo }
            return .aurora
        case .rare:
            // 20% none, 30% glow, 35% halo, 14% aurora, 1% cosmic
            if roll < 0.20 { return .none }
            if roll < 0.50 { return .glow }
            if roll < 0.85 { return .halo }
            if roll < 0.99 { return .aurora }
            return .cosmic
        case .legendary:
            // 5% none, 15% glow, 25% halo, 45% aurora, 9% cosmic, 1% storm/ethereal
            if roll < 0.05 { return .none }
            if roll < 0.20 { return .glow }
            if roll < 0.45 { return .halo }
            if roll < 0.90 { return .aurora }
            if roll < 0.99 { return .cosmic }
            return roll < 0.995 ? .storm : .ethereal
        case .mythic:
            // 1% none, 5% glow, 15% halo, 30% aurora, 30% cosmic, 19% storm/ethereal
            if roll < 0.01 { return .none }
            if roll < 0.06 { return .glow }
            if roll < 0.21 { return .halo }
            if roll < 0.51 { return .aurora }
            if roll < 0.81 { return .cosmic }
            return roll < 0.905 ? .storm : .ethereal
        }
    }

    private static func generateOzoneDensity(rarity: Rarity, rng: inout SeededRandomGenerator) -> Double {
        // Completely random ozone density
        return rng.nextDouble(min: 0.0, max: 1.0)
    }

    private static func generateSizeClass(rarity: Rarity, rng: inout SeededRandomGenerator) -> SizeClass {
        let roll = rng.nextDouble()

        switch rarity {
        case .common:
            // Early: 15% small, 70% medium, 15% large
            if roll < 0.15 { return .small }
            if roll < 0.85 { return .medium }
            return .large
        case .uncommon:
            // 10% tiny, 20% small, 40% medium, 20% large, 10% huge
            if roll < 0.10 { return .tiny }
            if roll < 0.30 { return .small }
            if roll < 0.70 { return .medium }
            if roll < 0.90 { return .large }
            return .huge
        case .rare:
            // 5% tiny, 15% small, 30% medium, 30% large, 15% huge, 5% gigantic
            if roll < 0.05 { return .tiny }
            if roll < 0.20 { return .small }
            if roll < 0.50 { return .medium }
            if roll < 0.80 { return .large }
            if roll < 0.95 { return .huge }
            return .gigantic
        case .legendary:
            // 5% miniscule, 10% tiny, 10% small, 20% medium, 20% large, 20% huge, 14% gigantic, 1% titanic
            if roll < 0.05 { return .miniscule }
            if roll < 0.15 { return .tiny }
            if roll < 0.25 { return .small }
            if roll < 0.45 { return .medium }
            if roll < 0.65 { return .large }
            if roll < 0.85 { return .huge }
            if roll < 0.99 { return .gigantic }
            return .titanic
        case .mythic:
            // 15% miniscule, 10% tiny, 10% small, 10% medium, 10% large, 10% huge, 15% gigantic, 20% titanic
            if roll < 0.15 { return .miniscule }
            if roll < 0.25 { return .tiny }
            if roll < 0.35 { return .small }
            if roll < 0.45 { return .medium }
            if roll < 0.55 { return .large }
            if roll < 0.65 { return .huge }
            if roll < 0.80 { return .gigantic }
            return .titanic
        }
    }

    private static func generateRandomColors(rng: inout SeededRandomGenerator) -> (primary: String, secondary: String, accent: String) {
        // Generate completely random colors with full RGB spectrum
        let primary = generateRandomColorHex(rng: &rng)
        let secondary = generateRandomColorHex(rng: &rng)
        let accent = generateRandomColorHex(rng: &rng)

        return (primary, secondary, accent)
    }

    private static func generateRandomColorHex(rng: inout SeededRandomGenerator) -> String {
        let r = rng.nextInt(min: 0, max: 255)
        let g = rng.nextInt(min: 0, max: 255)
        let b = rng.nextInt(min: 0, max: 255)

        return String(format: "%02X%02X%02X", r, g, b)
    }

    private static func generateName(rng: inout SeededRandomGenerator) -> String {
        let prefix = prefixes.randomElement(using: &rng)!
        let suffix = suffixes.randomElement(using: &rng)!
        let number = rng.nextInt(min: 1, max: 999)

        return "\(prefix)-\(suffix)-\(number)"
    }
}

// MARK: - Seeded Random Generator

/// Deterministic random number generator using a seed
/// This ensures that the same seed will always produce the same sequence of random numbers
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        // Initialize with seed
        state = UInt64(truncatingIfNeeded: seed)
        // Mix the seed a bit
        _ = next()
        _ = next()
    }

    mutating func next() -> UInt64 {
        // Linear congruential generator (simple but effective for our purposes)
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(UInt64(1) << 53)
    }

    mutating func nextDouble(min: Double, max: Double) -> Double {
        min + nextDouble() * (max - min)
    }

    mutating func nextInt(min: Int, max: Int) -> Int {
        Int(nextDouble(min: Double(min), max: Double(max + 1)))
    }
}

extension Array {
    func randomElement(using generator: inout SeededRandomGenerator) -> Element? {
        guard !isEmpty else { return nil }
        let index = generator.nextInt(min: 0, max: count - 1)
        return self[index]
    }
}
