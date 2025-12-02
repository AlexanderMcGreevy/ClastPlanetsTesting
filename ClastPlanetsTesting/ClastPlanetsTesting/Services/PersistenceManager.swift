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
    private let totalDistanceKey = "total_distance_travelled"
    private let favoritedPlanetIDsKey = "favorited_planet_ids"
    private let galaxyPlanetIDsKey = "galaxy_planet_ids"

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
}
