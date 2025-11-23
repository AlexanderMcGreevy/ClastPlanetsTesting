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
}
