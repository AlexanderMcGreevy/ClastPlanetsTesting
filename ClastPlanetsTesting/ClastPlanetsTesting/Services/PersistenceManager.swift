//
//  PersistenceManager.swift
//  ClastPlanetsTesting
//
//  Simple persistence using UserDefaults for saving/loading planets and settings
//

import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()

    private let defaults = UserDefaults.standard
    private let planetsKey = "discovered_planets"
    private let activePlanetIDKey = "active_planet_id"
    private let totalDistanceKey = "total_distance_travelled"
    private let favoritedPlanetIDsKey = "favorited_planet_ids"
    private let galaxyPlanetIDsKey = "galaxy_planet_ids"
    private let customPlanetPositionsKey = "custom_planet_positions"

    private init() {}

    // MARK: - Planets

    func savePlanets(_ planets: [Planet]) {
        if let encoded = try? JSONEncoder().encode(planets) {
            defaults.set(encoded, forKey: planetsKey)
        }
    }

    func loadPlanets() -> [Planet] {
        guard let data = defaults.data(forKey: planetsKey),
              let planets = try? JSONDecoder().decode([Planet].self, from: data) else {
            return []
        }
        return planets
    }

    // MARK: - Active Planet

    func saveActivePlanetID(_ id: UUID?) {
        if let id = id {
            defaults.set(id.uuidString, forKey: activePlanetIDKey)
        } else {
            defaults.removeObject(forKey: activePlanetIDKey)
        }
    }

    func loadActivePlanetID() -> UUID? {
        guard let uuidString = defaults.string(forKey: activePlanetIDKey) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }

    // MARK: - Total Distance

    func saveTotalDistance(_ distance: Double) {
        defaults.set(distance, forKey: totalDistanceKey)
    }

    func loadTotalDistance() -> Double {
        return defaults.double(forKey: totalDistanceKey)
    }

    // MARK: - Favorited Planets

    func saveFavoritedPlanetIDs(_ ids: Set<UUID>) {
        let uuidStrings = ids.map { $0.uuidString }
        defaults.set(uuidStrings, forKey: favoritedPlanetIDsKey)
    }

    func loadFavoritedPlanetIDs() -> Set<UUID> {
        guard let uuidStrings = defaults.array(forKey: favoritedPlanetIDsKey) as? [String] else {
            return []
        }
        return Set(uuidStrings.compactMap { UUID(uuidString: $0) })
    }

    // MARK: - Galaxy Planets

    func saveGalaxyPlanetIDs(_ ids: Set<UUID>) {
        let uuidStrings = ids.map { $0.uuidString }
        defaults.set(uuidStrings, forKey: galaxyPlanetIDsKey)
    }

    func loadGalaxyPlanetIDs() -> Set<UUID> {
        guard let uuidStrings = defaults.array(forKey: galaxyPlanetIDsKey) as? [String] else {
            return []
        }
        return Set(uuidStrings.compactMap { UUID(uuidString: $0) })
    }

    // MARK: - Custom Planet Positions

    func saveCustomPlanetPositions(_ positions: [UUID: CGPoint]) {
        // Convert to dictionary of [String: [String: Double]] for encoding
        let encodable = positions.reduce(into: [String: [String: Double]]()) { result, entry in
            result[entry.key.uuidString] = ["x": entry.value.x, "y": entry.value.y]
        }
        if let encoded = try? JSONEncoder().encode(encodable) {
            defaults.set(encoded, forKey: customPlanetPositionsKey)
        }
    }

    func loadCustomPlanetPositions() -> [UUID: CGPoint] {
        guard let data = defaults.data(forKey: customPlanetPositionsKey),
              let decoded = try? JSONDecoder().decode([String: [String: Double]].self, from: data) else {
            return [:]
        }

        return decoded.reduce(into: [UUID: CGPoint]()) { result, entry in
            guard let uuid = UUID(uuidString: entry.key),
                  let x = entry.value["x"],
                  let y = entry.value["y"] else {
                return
            }
            result[uuid] = CGPoint(x: x, y: y)
        }
    }
}
