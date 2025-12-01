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
        let availableTypes: [BaseType]

        switch rarity {
        case .common:
            availableTypes = [.solid]
        case .uncommon:
            availableTypes = [.solid, .striped, .cratered]
        case .rare:
            availableTypes = [.striped, .cratered, .swirled]
        case .legendary:
            availableTypes = [.swirled, .volcanic]
        case .mythic:
            availableTypes = [.crystalline, .nebulous, .prismatic]
        }

        return availableTypes.randomElement(using: &rng)!
    }

    private static func generateRingType(rarity: Rarity, rng: inout SeededRandomGenerator) -> RingType {
        let roll = rng.nextDouble()

        switch rarity {
        case .common:
            return roll < 0.7 ? .none : .simple
        case .uncommon:
            if roll < 0.4 { return .none }
            if roll < 0.9 { return .simple }
            return .double
        case .rare:
            if roll < 0.2 { return .simple }
            if roll < 0.7 { return .double }
            return .chunky
        case .legendary:
            if roll < 0.3 { return .double }
            if roll < 0.7 { return .chunky }
            return .rainbow
        case .mythic:
            return .crossed
        }
    }

    private static func generateMoonCount(rarity: Rarity, rng: inout SeededRandomGenerator) -> Int {
        let roll = rng.nextDouble()

        switch rarity {
        case .common:
            return roll < 0.7 ? 0 : 1
        case .uncommon:
            if roll < 0.3 { return 0 }
            if roll < 0.8 { return 1 }
            return 2
        case .rare:
            if roll < 0.2 { return 1 }
            if roll < 0.7 { return 2 }
            return 3
        case .legendary:
            return rng.nextInt(min: 2, max: 3)
        case .mythic:
            return rng.nextInt(min: 3, max: 4)
        }
    }

    private static func generateAtmosphereType(rarity: Rarity, rng: inout SeededRandomGenerator) -> AtmosphereType {
        let roll = rng.nextDouble()

        switch rarity {
        case .common:
            return roll < 0.6 ? .none : .glow
        case .uncommon:
            if roll < 0.3 { return .none }
            if roll < 0.8 { return .glow }
            return .halo
        case .rare:
            if roll < 0.3 { return .halo }
            if roll < 0.8 { return .aurora }
            return .halo
        case .legendary:
            if roll < 0.5 { return .aurora }
            return .cosmic
        case .mythic:
            return roll < 0.5 ? .storm : .ethereal
        }
    }

    private static func generateOzoneDensity(rarity: Rarity, rng: inout SeededRandomGenerator) -> Double {
        // Higher rarity planets tend to have denser ozone layers
        switch rarity {
        case .common:
            return rng.nextDouble(min: 0.0, max: 0.3)
        case .uncommon:
            return rng.nextDouble(min: 0.2, max: 0.5)
        case .rare:
            return rng.nextDouble(min: 0.4, max: 0.7)
        case .legendary:
            return rng.nextDouble(min: 0.6, max: 1.0)
        case .mythic:
            return rng.nextDouble(min: 0.8, max: 1.0)
        }
    }

    private static func generateSizeClass(rarity: Rarity, rng: inout SeededRandomGenerator) -> SizeClass {
        let roll = rng.nextDouble()

        switch rarity {
        case .common:
            // Common planets are mostly medium-sized
            if roll < 0.70 { return .medium }
            if roll < 0.85 { return .small }
            return .large
        case .uncommon:
            // Uncommon planets have more variety
            if roll < 0.25 { return .small }
            if roll < 0.50 { return .medium }
            if roll < 0.75 { return .large }
            return .tiny
        case .rare:
            // Rare planets can be quite varied
            if roll < 0.20 { return .tiny }
            if roll < 0.40 { return .small }
            if roll < 0.60 { return .large }
            if roll < 0.80 { return .huge }
            return .medium
        case .legendary:
            // Legendary planets favor extreme sizes
            if roll < 0.30 { return .huge }
            if roll < 0.60 { return .gigantic }
            if roll < 0.80 { return .tiny }
            return .large
        case .mythic:
            // Mythic planets are the extremes
            if roll < 0.50 { return .titanic }
            return .miniscule
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
