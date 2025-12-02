//
//  Models.swift
//  ClastPlanetsTesting
//
//  Planet models and component types for the discovery system
//

import Foundation
import SwiftUI

// MARK: - Rarity

enum Rarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case legendary
    case mythic

    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .legendary: return .purple
        case .mythic: return .orange
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var sortOrder: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .legendary: return 3
        case .mythic: return 4
        }
    }
}

// MARK: - Planet Components

enum BaseType: String, Codable, CaseIterable {
    case solid
    case striped
    case cratered
    case swirled
    case volcanic
    case crystalline
    case nebulous
    case prismatic

    var rarity: Rarity {
        switch self {
        case .solid: return .common
        case .striped: return .uncommon
        case .cratered: return .uncommon
        case .swirled: return .rare
        case .volcanic: return .legendary
        case .crystalline: return .mythic
        case .nebulous: return .mythic
        case .prismatic: return .mythic
        }
    }
}

enum RingType: String, Codable, CaseIterable {
    case none
    case simple
    case double
    case chunky
    case rainbow
    case crossed

    var rarity: Rarity {
        switch self {
        case .none: return .common
        case .simple: return .uncommon
        case .double: return .rare
        case .chunky: return .rare
        case .rainbow: return .legendary
        case .crossed: return .mythic
        }
    }
}

enum AtmosphereType: String, Codable, CaseIterable {
    case none
    case glow
    case halo
    case aurora
    case cosmic
    case storm
    case ethereal

    var rarity: Rarity {
        switch self {
        case .none: return .common
        case .glow: return .uncommon
        case .halo: return .rare
        case .aurora: return .rare
        case .cosmic: return .legendary
        case .storm: return .mythic
        case .ethereal: return .mythic
        }
    }
}

enum SizeClass: String, Codable, CaseIterable {
    case miniscule
    case tiny
    case small
    case medium
    case large
    case huge
    case gigantic
    case titanic

    var displayName: String {
        rawValue.capitalized
    }

    var sizeRange: (min: Double, max: Double) {
        switch self {
        case .miniscule: return (0.3, 0.5)
        case .tiny: return (0.5, 0.7)
        case .small: return (0.7, 0.9)
        case .medium: return (0.9, 1.1)
        case .large: return (1.1, 1.3)
        case .huge: return (1.3, 1.6)
        case .gigantic: return (1.6, 2.0)
        case .titanic: return (2.0, 2.5)
        }
    }

    var rarity: Rarity {
        switch self {
        case .miniscule: return .mythic
        case .tiny: return .rare
        case .small: return .uncommon
        case .medium: return .common
        case .large: return .uncommon
        case .huge: return .rare
        case .gigantic: return .legendary
        case .titanic: return .mythic
        }
    }

    var sortOrder: Int {
        switch self {
        case .miniscule: return 0
        case .tiny: return 1
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        case .huge: return 5
        case .gigantic: return 6
        case .titanic: return 7
        }
    }
}

enum SurfaceType: String, Codable, CaseIterable {
    case smooth
    case rocky
    case icy
    case desert
    case oceanic
    case volcanic
    case crystalline
    case molten
    case prismatic
    case voidlike

    var displayName: String {
        rawValue.capitalized
    }

    var rarity: Rarity {
        switch self {
        case .smooth: return .common
        case .rocky: return .common
        case .desert: return .uncommon
        case .icy: return .uncommon
        case .oceanic: return .rare
        case .volcanic: return .rare
        case .crystalline: return .legendary
        case .molten: return .legendary
        case .prismatic: return .mythic
        case .voidlike: return .mythic
        }
    }
}

// MARK: - Planet

struct Planet: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let distanceDiscoveredAt: Double
    let rarity: Rarity
    let seed: Int

    // Visual components
    let baseType: BaseType
    let surfaceType: SurfaceType
    let ringType: RingType
    let moonCount: Int // 0-3
    let atmosphereType: AtmosphereType
    let sizeClass: SizeClass
    let size: Double // Actual size value within the sizeClass range
    let ozoneDensity: Double // 0.0 to 1.0 - controls ozone layer opacity/intensity
    let ringTilt: Double // Rotation angle for rings in degrees (0-360)
    let ringWidth: Double // Multiplier for ring line width (0.5-2.0)

    // Colors (stored as hex strings for Codable)
    let primaryColorHex: String
    let secondaryColorHex: String
    let accentColorHex: String

    // Computed properties for SwiftUI
    var primaryColor: Color {
        Color(hex: primaryColorHex)
    }

    var secondaryColor: Color {
        Color(hex: secondaryColorHex)
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    // Calculate overall rarity based on highest rarity component
    var calculatedRarity: Rarity {
        let rarities = [baseType.rarity, surfaceType.rarity, ringType.rarity, atmosphereType.rarity, sizeClass.rarity]

        // Find the highest rarity
        return rarities.max(by: { $0.sortOrder < $1.sortOrder }) ?? .common
    }

    // Count how many traits are at the highest rarity level
    var highestRarityCount: Int {
        let rarities = [baseType.rarity, surfaceType.rarity, ringType.rarity, atmosphereType.rarity, sizeClass.rarity]
        let highest = calculatedRarity
        return rarities.filter { $0 == highest }.count
    }

    // Display name with rarity count (e.g., "Legendary 3")
    var rarityDisplayName: String {
        let count = highestRarityCount
        return "\(calculatedRarity.displayName) \(count)"
    }

    // Description text
    var description: String {
        var parts: [String] = []

        parts.append("Base: \(baseType.rawValue.capitalized)")

        if ringType != .none {
            parts.append("Rings: \(ringType.rawValue.capitalized)")
        }

        if moonCount > 0 {
            parts.append("Moons: \(moonCount)")
        }

        if atmosphereType != .none {
            parts.append("Atmosphere: \(atmosphereType.rawValue.capitalized)")
        }

        return parts.joined(separator: " • ")
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, int >> 24)
        default:
            (r, g, b, a) = (128, 128, 128, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "808080" }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "%02X%02X%02X", r, g, b)
    }
}
