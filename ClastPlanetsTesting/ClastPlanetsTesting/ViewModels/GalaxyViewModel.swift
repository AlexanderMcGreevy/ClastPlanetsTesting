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

    // Favorited planets
    var favoritedPlanetIDs: Set<UUID> = [] {
        didSet {
            PersistenceManager.shared.saveFavoritedPlanetIDs(favoritedPlanetIDs)
        }
    }

    // Planets selected for galaxy view
    var galaxyPlanetIDs: Set<UUID> = [] {
        didSet {
            PersistenceManager.shared.saveGalaxyPlanetIDs(galaxyPlanetIDs)
        }
    }

    // Custom positions for planets in galaxy view (in normalized coordinates 0.0-1.0)
    var customPlanetPositions: [UUID: CGPoint] = [:] {
        didSet {
            PersistenceManager.shared.saveCustomPlanetPositions(customPlanetPositions)
        }
    }

    // Current planet preview (not yet discovered)
    var currentPreviewPlanet: Planet?

    // Orbit indices for planets in galaxy view
    var planetOrbits: [UUID: Int] = [:]

    // MARK: - Computed Properties

    var activePlanet: Planet? {
        guard let id = activePlanetID else { return nil }
        return discoveredPlanets.first { $0.id == id }
    }

    var sortedPlanets: [Planet] {
        discoveredPlanets.sorted { $0.distanceDiscoveredAt < $1.distanceDiscoveredAt }
    }

    var galaxyPlanets: [Planet] {
        discoveredPlanets.filter { galaxyPlanetIDs.contains($0.id) }
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
        favoritedPlanetIDs = PersistenceManager.shared.loadFavoritedPlanetIDs()
        galaxyPlanetIDs = PersistenceManager.shared.loadGalaxyPlanetIDs()
        customPlanetPositions = PersistenceManager.shared.loadCustomPlanetPositions()

        // If we have planets but no active planet, set the first one as active
        if activePlanetID == nil && !discoveredPlanets.isEmpty {
            activePlanetID = discoveredPlanets.first?.id
        }

        // Auto-select first 6 planets for galaxy if none selected
        if galaxyPlanetIDs.isEmpty && !discoveredPlanets.isEmpty {
            galaxyPlanetIDs = Set(sortedPlanets.prefix(min(6, sortedPlanets.count)).map { $0.id })
        }

        // Initialize planet orbits
        updatePlanetOrbits()
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

    // MARK: - Favoriting

    func toggleFavorite(_ planet: Planet) {
        toggleFavorite(planet.id)
    }

    func toggleFavorite(_ planetID: UUID) {
        if favoritedPlanetIDs.contains(planetID) {
            favoritedPlanetIDs.remove(planetID)
        } else {
            favoritedPlanetIDs.insert(planetID)
        }
    }

    func isFavorited(_ planet: Planet) -> Bool {
        isFavorited(planet.id)
    }

    func isFavorited(_ planetID: UUID) -> Bool {
        favoritedPlanetIDs.contains(planetID)
    }

    // MARK: - Galaxy Management

    func addToGalaxy(_ planet: Planet) {
        addToGalaxy(planet.id)
    }

    func addToGalaxy(_ planetID: UUID) {
        if galaxyPlanetIDs.count < 10 {
            galaxyPlanetIDs.insert(planetID)
            updatePlanetOrbits()
        }
    }

    func removeFromGalaxy(_ planet: Planet) {
        removeFromGalaxy(planet.id)
    }

    func removeFromGalaxy(_ planetID: UUID) {
        galaxyPlanetIDs.remove(planetID)
        updatePlanetOrbits()
    }

    func toggleGalaxy(_ planet: Planet) {
        toggleGalaxy(planet.id)
    }

    func toggleGalaxy(_ planetID: UUID) {
        if galaxyPlanetIDs.contains(planetID) {
            removeFromGalaxy(planetID)
        } else {
            addToGalaxy(planetID)
        }
    }

    func isInGalaxy(_ planet: Planet) -> Bool {
        isInGalaxy(planet.id)
    }

    func isInGalaxy(_ planetID: UUID) -> Bool {
        galaxyPlanetIDs.contains(planetID)
    }

    func updatePlanetOrbits() {
        let sorted = galaxyPlanets.sorted(by: { $0.distanceDiscoveredAt < $1.distanceDiscoveredAt })
        planetOrbits = [:]
        for (index, planet) in sorted.enumerated() {
            planetOrbits[planet.id] = index
        }
    }

    // MARK: - Custom Positions

    func setCustomPosition(for planetID: UUID, position: CGPoint) {
        customPlanetPositions[planetID] = position
    }

    func getCustomPosition(for planetID: UUID) -> CGPoint? {
        customPlanetPositions[planetID]
    }

    func clearCustomPosition(for planetID: UUID) {
        customPlanetPositions.removeValue(forKey: planetID)
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

    // MARK: - Trait Discovery

    func hasDiscoveredTrait(baseType: BaseType) -> Bool {
        discoveredPlanets.contains(where: { $0.baseType == baseType })
    }

    func hasDiscoveredTrait(ringType: RingType) -> Bool {
        discoveredPlanets.contains(where: { $0.ringType == ringType })
    }

    func hasDiscoveredTrait(atmosphereType: AtmosphereType) -> Bool {
        discoveredPlanets.contains(where: { $0.atmosphereType == atmosphereType })
    }

    func hasDiscoveredTrait(sizeClass: SizeClass) -> Bool {
        discoveredPlanets.contains(where: { $0.sizeClass == sizeClass })
    }

    // MARK: - Trait Statistics

    func collectedTraitsCount(for rarity: Rarity) -> Int {
        var count = 0

        // Count base types
        for baseType in BaseType.allCases where baseType.rarity == rarity {
            if hasDiscoveredTrait(baseType: baseType) {
                count += 1
            }
        }

        // Count ring types
        for ringType in RingType.allCases where ringType != .none && ringType.rarity == rarity {
            if hasDiscoveredTrait(ringType: ringType) {
                count += 1
            }
        }

        // Count atmosphere types
        for atmosphereType in AtmosphereType.allCases where atmosphereType != .none && atmosphereType.rarity == rarity {
            if hasDiscoveredTrait(atmosphereType: atmosphereType) {
                count += 1
            }
        }

        // Count size classes
        for sizeClass in SizeClass.allCases where sizeClass.rarity == rarity {
            if hasDiscoveredTrait(sizeClass: sizeClass) {
                count += 1
            }
        }

        return count
    }

    func totalTraitsCount(for rarity: Rarity) -> Int {
        var count = 0

        // Base types
        count += BaseType.allCases.filter { $0.rarity == rarity }.count

        // Ring types (excluding .none)
        count += RingType.allCases.filter { $0 != .none && $0.rarity == rarity }.count

        // Atmosphere types (excluding .none)
        count += AtmosphereType.allCases.filter { $0 != .none && $0.rarity == rarity }.count

        // Size classes
        count += SizeClass.allCases.filter { $0.rarity == rarity }.count

        return count
    }

    var totalCollectedTraits: Int {
        Rarity.allCases.reduce(0) { $0 + collectedTraitsCount(for: $1) }
    }

    var totalTraits: Int {
        Rarity.allCases.reduce(0) { $0 + totalTraitsCount(for: $1) }
    }
}
