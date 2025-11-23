//
//  GalaxyViewModel.swift
//  ClastPlanetsTesting
//
//  Central state management for the planet discovery system
//

import Foundation
import SwiftUI

@Observable
class GalaxyViewModel {

    // MARK: - State

    var totalDistanceTravelled: Double = 0.0 {
        didSet {
            PersistenceManager.shared.saveTotalDistance(totalDistanceTravelled)
        }
    }

    var discoveredPlanets: [Planet] = [] {
        didSet {
            PersistenceManager.shared.savePlanets(discoveredPlanets)
        }
    }

    var activePlanetID: UUID? = nil {
        didSet {
            PersistenceManager.shared.saveActivePlanetID(activePlanetID)
        }
    }

    // Current planet preview (not yet discovered)
    var currentPreviewPlanet: Planet?

    // MARK: - Computed Properties

    var activePlanet: Planet? {
        guard let id = activePlanetID else { return nil }
        return discoveredPlanets.first { $0.id == id }
    }

    var sortedPlanets: [Planet] {
        discoveredPlanets.sorted { $0.distanceDiscoveredAt < $1.distanceDiscoveredAt }
    }

    // MARK: - Initialization

    init() {
        loadPersistedData()
        generatePreviewPlanet()
    }

    // MARK: - Persistence

    private func loadPersistedData() {
        totalDistanceTravelled = PersistenceManager.shared.loadTotalDistance()
        discoveredPlanets = PersistenceManager.shared.loadPlanets()
        activePlanetID = PersistenceManager.shared.loadActivePlanetID()

        // If we have planets but no active planet, set the first one as active
        if activePlanetID == nil && !discoveredPlanets.isEmpty {
            activePlanetID = discoveredPlanets.first?.id
        }
    }

    // MARK: - Planet Generation

    /// Generate a preview planet based on current distance
    func generatePreviewPlanet() {
        currentPreviewPlanet = PlanetGenerator.generatePlanet(atDistance: totalDistanceTravelled)
    }

    /// Discover the current preview planet and add it to the collection
    func discoverPlanet() {
        guard let planet = currentPreviewPlanet else { return }

        // Add to discovered planets if not already there
        if !discoveredPlanets.contains(where: { $0.id == planet.id }) {
            discoveredPlanets.append(planet)

            // If this is the first planet, make it active
            if activePlanetID == nil {
                activePlanetID = planet.id
            }
        }

        // Generate a new preview
        generatePreviewPlanet()
    }

    // MARK: - Active Planet Management

    func setActivePlanet(_ planet: Planet) {
        activePlanetID = planet.id
    }

    // MARK: - Statistics

    var totalPlanetsDiscovered: Int {
        discoveredPlanets.count
    }

    var planetsByRarity: [Rarity: Int] {
        var counts: [Rarity: Int] = [:]
        for rarity in Rarity.allCases {
            counts[rarity] = discoveredPlanets.filter { $0.rarity == rarity }.count
        }
        return counts
    }

    var rarestPlanet: Planet? {
        discoveredPlanets.max { p1, p2 in
            let order: [Rarity] = [.common, .uncommon, .rare, .legendary]
            let index1 = order.firstIndex(of: p1.rarity) ?? 0
            let index2 = order.firstIndex(of: p2.rarity) ?? 0
            return index1 < index2
        }
    }
}
