import SwiftUI

/// Unified view that combines Galaxy, Collection, and Dictionary into one screen
/// with a glassy corner icon stack for navigation
struct UnifiedPlanetView: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @State private var selectedTab: UnifiedTab = .galaxy
    @State private var isDetailPresented: Bool = false
    @State private var isScrolling: Bool = false

    enum UnifiedTab: Int, CaseIterable {
        case galaxy = 0
        case collection = 1
        case dictionary = 2

        var icon: String {
            switch self {
            case .galaxy: return "sparkles"
            case .collection: return "square.stack.3d.up.fill"
            case .dictionary: return "book.fill"
            }
        }

        var color: Color {
            switch self {
            case .galaxy: return .yellow
            case .collection: return .blue
            case .dictionary: return .green
            }
        }

        var title: String {
            switch self {
            case .galaxy: return "Galaxy"
            case .collection: return "Collection"
            case .dictionary: return "Dictionary"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Content area
            Group {
                switch selectedTab {
                case .galaxy:
                    GalaxyViewContent(isDetailPresented: $isDetailPresented)
                case .collection:
                    CollectionViewContent(isDetailPresented: $isDetailPresented, isScrolling: $isScrolling)
                case .dictionary:
                    DictionaryViewContent(isDetailPresented: $isDetailPresented, isScrolling: $isScrolling)
                }
            }

            // Corner icon stack - hidden when detail view is presented
            if !isDetailPresented {
                cornerIconStack
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var cornerIconStack: some View {
        VStack(spacing: 10) {
            ForEach(UnifiedTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                        isScrolling = false // Expand tabs when clicked
                    }
                } label: {
                    Group {
                        if isScrolling {
                            // Small dot version
                            Circle()
                                .fill(selectedTab == tab ? tab.color : tab.color.opacity(0.5))
                                .frame(width: 12, height: 12)
                        } else {
                            // Full icon version
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(selectedTab == tab ? .white : tab.color)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(selectedTab == tab ? tab.color : Color.clear)
                                )
                                .background(
                                    // Glassy frosted background
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(selectedTab == tab ? tab.color.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isScrolling)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 16)
        .padding(.top, 16)
    }
}

// MARK: - Galaxy View Content

struct GalaxyViewContent: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isDetailPresented: Bool

    @State private var showingPlanetPicker = false
    @State private var isEditMode = false
    @State private var selectedPlanetForInfo: Planet?
    @State private var zoomScale: CGFloat = 1.0
    @State private var baseZoomScale: CGFloat = 1.0
    @State private var ringSpacing: Double = 80

    private var sortedGalaxyPlanets: [Planet] {
        viewModel.galaxyPlanets.sorted(by: {
            (viewModel.planetOrbits[$0.id] ?? 0) < (viewModel.planetOrbits[$1.id] ?? 0)
        })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.galaxyPlanets.isEmpty {
                    noPlanetState
                } else {
                    VStack(spacing: 0) {
                        solarSystemView
                        if isEditMode {
                            controlsSection
                        }
                    }
                }
            }
            .navigationTitle("Galaxy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditMode ? "Done" : "Edit") {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPlanetPicker) {
                SimplePlanetSelectionSheet()
                    .environment(viewModel)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedPlanetForInfo) { planet in
                PlanetDetailView(planet: planet)
                    .environment(viewModel)
            }
            .onChange(of: showingPlanetPicker) { _, newValue in
                withAnimation {
                    isDetailPresented = newValue
                }
            }
            .onChange(of: selectedPlanetForInfo) { _, newValue in
                withAnimation {
                    isDetailPresented = newValue != nil
                }
            }
            .onAppear {
                // Ensure planet orbits are updated when view appears
                viewModel.updatePlanetOrbits()
            }
        }
    }

    private var noPlanetState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.yellow.opacity(0.5))

            Text("No Planets in Galaxy")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("Add planets from your collection to view your solar system")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingPlanetPicker = true
            } label: {
                Label("Select Planets", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            }
            .padding(.top)
        }
    }

    private var solarSystemView: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let center = CGPoint(x: centerX, y: centerY)
            let maxRadius = min(geometry.size.width, geometry.size.height) * 0.45
            let totalOrbits = viewModel.galaxyPlanets.count

            ZStack {
                starsBackground

                ForEach(sortedGalaxyPlanets) { planet in
                    if let orbitIndex = viewModel.planetOrbits[planet.id] {
                        OrbitPlanetView(
                            planet: planet,
                            orbitIndex: orbitIndex,
                            totalOrbits: totalOrbits,
                            center: center,
                            maxRadius: maxRadius,
                            ringSpacing: CGFloat(ringSpacing) * zoomScale,
                            reduceMotion: reduceMotion,
                            isEditMode: isEditMode,
                            onOrbitChange: { newOrbit in
                                viewModel.updatePlanetOrbits()
                            },
                            onTap: {
                                if !isEditMode {
                                    selectedPlanetForInfo = planet
                                }
                            }
                        )
                        .environment(viewModel)
                    }
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.yellow, .orange],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120 * zoomScale, height: 120 * zoomScale)
                    .shadow(color: .yellow.opacity(0.6), radius: 30)
                    .position(x: centerX, y: centerY)
                    .allowsHitTesting(false)
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomScale = baseZoomScale * value
                    }
                    .onEnded { value in
                        baseZoomScale = zoomScale
                    }
            )
        }
    }

    private var starsBackground: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<200, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...1.0)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(viewModel.galaxyPlanets.count) planet\(viewModel.galaxyPlanets.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Button {
                    showingPlanetPicker = true
                } label: {
                    Label("Manage", systemImage: "pencil")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Ring Spacing")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(ringSpacing))")
                        .font(.caption)
                        .foregroundStyle(.white)
                }

                Slider(value: $ringSpacing, in: 40...120, step: 5)
                    .tint(.blue)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
}

// MARK: - Collection View Content

struct CollectionViewContent: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @Binding var isDetailPresented: Bool
    @Binding var isScrolling: Bool

    @State private var sortOption: SortOption = .distance
    @State private var previousSortOption: SortOption = .distance
    @State private var isReversed: Bool = false
    @State private var favoritesOnly = false
    @State private var selectedPlanet: Planet?
    @State private var scrollOffset: CGFloat = 0

    enum SortOption: String, CaseIterable {
        case distance = "Distance"
        case rarity = "Rarity"
        case name = "Name"
        case favorites = "Favorites"
        case size = "Size"
        case moons = "Moons"
        case recent = "Recently Discovered"
        case baseType = "Base Type"
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.discoveredPlanets.isEmpty {
                    emptyState
                } else {
                    planetList
                }
            }
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                if sortOption == option {
                                    // Same option - toggle reverse
                                    isReversed.toggle()
                                } else {
                                    // New option - reset reverse
                                    sortOption = option
                                    isReversed = false
                                }
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: isReversed ? "arrow.up" : "arrow.down")
                                    }
                                }
                            }
                        }

                        Divider()

                        Toggle("Favorites Only", isOn: $favoritesOnly)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(item: $selectedPlanet) { planet in
                PlanetDetailView(planet: planet)
                    .environment(viewModel)
            }
            .onChange(of: selectedPlanet) { _, newValue in
                withAnimation {
                    isDetailPresented = newValue != nil
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.5))

            Text("No Planets Discovered")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Generate your first planet to start your collection")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var planetList: some View {
        List {
            Section {
                ForEach(sortedPlanets) { planet in
                    Button {
                        selectedPlanet = planet
                    } label: {
                        PlanetRow(planet: planet, viewModel: viewModel)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.toggleFavorite(planet.id)
                        } label: {
                            Label(
                                viewModel.isFavorited(planet.id) ? "Unfavorite" : "Favorite",
                                systemImage: viewModel.isFavorited(planet.id) ? "star.slash" : "star.fill"
                            )
                        }
                        .tint(.yellow)

                        Button {
                            viewModel.toggleGalaxy(planet.id)
                        } label: {
                            Label(
                                viewModel.isInGalaxy(planet.id) ? "Remove from Galaxy" : "Add to Galaxy",
                                systemImage: viewModel.isInGalaxy(planet.id) ? "minus.circle" : "plus.circle"
                            )
                        }
                        .tint(viewModel.isInGalaxy(planet.id) ? .red : .blue)
                    }
                }
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldValue, newValue in
            // Detect scrolling down
            if newValue > 50 {
                isScrolling = true
            } else if newValue < 10 {
                isScrolling = false
            }
        }
    }

    private var sortedPlanets: [Planet] {
        var planets = favoritesOnly
            ? viewModel.discoveredPlanets.filter { viewModel.isFavorited($0.id) }
            : viewModel.discoveredPlanets

        switch sortOption {
        case .distance:
            planets.sort(by: { $0.distanceDiscoveredAt < $1.distanceDiscoveredAt })
        case .rarity:
            planets.sort(by: { $0.rarity.sortOrder < $1.rarity.sortOrder })
        case .name:
            planets.sort(by: { $0.name < $1.name })
        case .favorites:
            planets.sort(by: { viewModel.isFavorited($0.id) && !viewModel.isFavorited($1.id) })
        case .size:
            planets.sort(by: { $0.sizeClass.sortOrder > $1.sizeClass.sortOrder })
        case .moons:
            planets.sort(by: { $0.moonCount > $1.moonCount })
        case .recent:
            planets.reverse()
        case .baseType:
            planets.sort(by: { $0.baseType.rawValue < $1.baseType.rawValue })
        }

        // Reverse if the same filter was clicked again
        if isReversed {
            planets.reverse()
        }

        return planets
    }
}

// MARK: - Dictionary View Content

struct DictionaryViewContent: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @Binding var isDetailPresented: Bool
    @Binding var isScrolling: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Base Types") {
                    ForEach(BaseType.allCases, id: \.self) { baseType in
                        TraitRow(
                            name: baseType.rawValue.capitalized,
                            rarity: baseType.rarity,
                            isCollected: viewModel.hasDiscoveredTrait(baseType: baseType)
                        )
                    }
                }

                Section("Ring Types") {
                    ForEach(RingType.allCases.filter { $0 != .none }, id: \.self) { ringType in
                        TraitRow(
                            name: ringType.rawValue.capitalized,
                            rarity: ringType.rarity,
                            isCollected: viewModel.hasDiscoveredTrait(ringType: ringType)
                        )
                    }
                }

                Section("Atmosphere Types") {
                    ForEach(AtmosphereType.allCases.filter { $0 != .none }, id: \.self) { atmosphereType in
                        TraitRow(
                            name: atmosphereType.rawValue.capitalized,
                            rarity: atmosphereType.rarity,
                            isCollected: viewModel.hasDiscoveredTrait(atmosphereType: atmosphereType)
                        )
                    }
                }

                Section("Size Classes") {
                    ForEach(SizeClass.allCases, id: \.self) { sizeClass in
                        TraitRow(
                            name: sizeClass.rawValue.capitalized,
                            rarity: sizeClass.rarity,
                            isCollected: viewModel.hasDiscoveredTrait(sizeClass: sizeClass)
                        )
                    }
                }

                Section("Collection Statistics") {
                    statisticsView
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { oldValue, newValue in
                // Detect scrolling down
                if newValue > 50 {
                    isScrolling = true
                } else if newValue < 10 {
                    isScrolling = false
                }
            }
            .navigationTitle("Dictionary")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var statisticsView: some View {
        VStack(spacing: 12) {
            ForEach(Rarity.allCases, id: \.self) { rarity in
                HStack {
                    Circle()
                        .fill(rarity.color)
                        .frame(width: 12, height: 12)

                    Text(rarity.rawValue.capitalized)
                        .font(.subheadline)

                    Spacer()

                    Text("\(viewModel.collectedTraitsCount(for: rarity)) / \(viewModel.totalTraitsCount(for: rarity))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Text("Total Traits")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.totalCollectedTraits) / \(viewModel.totalTraits)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    UnifiedPlanetView()
        .environment(GalaxyViewModel())
}
