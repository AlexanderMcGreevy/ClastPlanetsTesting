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
                            // Small dot version with adequate tap target
                            ZStack {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 44, height: 44)
                                Circle()
                                    .fill(selectedTab == tab ? tab.color : tab.color.opacity(0.5))
                                    .frame(width: 12, height: 12)
                            }
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
        .padding(.top, 60)
        .padding(.trailing, 8)
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
    @State private var ringSpacing: Double = 70
    @State private var draggedPlanetID: UUID? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var isZooming: Bool = false
    @State private var panOffset: CGSize = .zero
    @State private var basePanOffset: CGSize = .zero
    @State private var isPanning: Bool = false

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
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            solarSystemView
                            if isEditMode {
                                controlsSection
                            }
                        }
                        .offset(panOffset)
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            MagnificationGesture(minimumScaleDelta: 0)
                                .onChanged { value in
                                    isZooming = true
                                    zoomScale = baseZoomScale * value
                                }
                                .onEnded { value in
                                    baseZoomScale = zoomScale
                                    // Delay resetting zoom state to prevent immediate drag
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isZooming = false
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    // Only pan if not dragging a planet in edit mode
                                    guard draggedPlanetID == nil && !isZooming else { return }
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        isPanning = true
                                        panOffset = CGSize(
                                            width: basePanOffset.width + value.translation.width,
                                            height: basePanOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { value in
                                    guard draggedPlanetID == nil else { return }
                                    basePanOffset = panOffset
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        isPanning = false
                                    }
                                }
                        )
                    }
                    .onTapGesture(count: 2) {
                        // Double tap to reset zoom and pan
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            zoomScale = 1.0
                            baseZoomScale = 1.0
                            panOffset = .zero
                            basePanOffset = .zero
                        }
                    }
                }
            }
            .navigationTitle("Galaxy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if zoomScale != 1.0 || panOffset != .zero {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                zoomScale = 1.0
                                baseZoomScale = 1.0
                                panOffset = .zero
                                basePanOffset = .zero
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                }

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

            ZStack {
                starsBackground

                // Sun - render first so planets appear on top
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

                // Orbit rings and planets
                TimelineView(.animation(paused: reduceMotion)) { timeline in
                    ZStack {
                        // Draw all orbit rings first
                        ForEach(sortedGalaxyPlanets) { planet in
                            if let orbitIndex = viewModel.planetOrbits[planet.id] {
                                let orbitRadius = CGFloat(orbitIndex + 1) * CGFloat(ringSpacing) * zoomScale

                                // Calculate if this is the target orbit during drag
                                let isTargetOrbit: Bool = {
                                    guard isEditMode, let draggedID = draggedPlanetID else { return false }
                                    if let draggedOrbitIndex = viewModel.planetOrbits[draggedID] {
                                        let draggedAngle = (timeline.date.timeIntervalSinceReferenceDate / Double(5 + draggedOrbitIndex * 2)).truncatingRemainder(dividingBy: 2 * .pi)
                                        let draggedOrbitRadius = CGFloat(draggedOrbitIndex + 1) * CGFloat(ringSpacing) * zoomScale
                                        let draggedPlanetX = centerX + cos(draggedAngle) * draggedOrbitRadius
                                        let draggedPlanetY = centerY + sin(draggedAngle) * draggedOrbitRadius
                                        let finalDragX = draggedPlanetX + dragOffset.width
                                        let finalDragY = draggedPlanetY + dragOffset.height
                                        let dx = finalDragX - centerX
                                        let dy = finalDragY - centerY
                                        let distanceFromCenter = sqrt(dx * dx + dy * dy)
                                        let targetOrbitIndex = max(0, min(sortedGalaxyPlanets.count - 1, Int(round(distanceFromCenter / (CGFloat(ringSpacing) * zoomScale))) - 1))
                                        return targetOrbitIndex == orbitIndex
                                    }
                                    return false
                                }()

                                Circle()
                                    .stroke(isTargetOrbit ? Color.blue.opacity(0.7) : Color.white.opacity(0.2), lineWidth: isTargetOrbit ? 3 : 1)
                                    .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                                    .position(x: centerX, y: centerY)
                                    .animation(.spring(response: 0.3), value: isTargetOrbit)
                            }
                        }

                        // Draw all planets on top
                        ForEach(sortedGalaxyPlanets) { planet in
                            if let orbitIndex = viewModel.planetOrbits[planet.id] {
                                let orbitRadius = CGFloat(orbitIndex + 1) * CGFloat(ringSpacing) * zoomScale
                                let speed = Double(5 + orbitIndex * 2)
                                let angle = (timeline.date.timeIntervalSinceReferenceDate / speed).truncatingRemainder(dividingBy: 2 * .pi)

                                let planetX = centerX + cos(angle) * orbitRadius
                                let planetY = centerY + sin(angle) * orbitRadius

                                // Apply drag offset if this planet is being dragged
                                let finalX = draggedPlanetID == planet.id ? planetX + dragOffset.width : planetX
                                let finalY = draggedPlanetID == planet.id ? planetY + dragOffset.height : planetY

                                PlanetView(planet: planet, size: 60, animated: true)
                                    .position(x: finalX, y: finalY)
                                    .opacity(draggedPlanetID == planet.id && isEditMode ? 0.7 : 1.0)
                                    .onTapGesture {
                                        if !isEditMode {
                                            selectedPlanetForInfo = planet
                                        }
                                    }
                                    .gesture(
                                        (isEditMode && !isZooming && !isPanning) ? DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                draggedPlanetID = planet.id
                                                dragOffset = value.translation
                                            }
                                            .onEnded { value in
                                                // Calculate final position
                                                let finalDragX = finalX
                                                let finalDragY = finalY

                                                // Calculate distance from center
                                                let dx = finalDragX - centerX
                                                let dy = finalDragY - centerY
                                                let distanceFromCenter = sqrt(dx * dx + dy * dy)

                                                // Determine which orbit this corresponds to
                                                let targetOrbitIndex = max(0, min(sortedGalaxyPlanets.count - 1, Int(round(distanceFromCenter / (CGFloat(ringSpacing) * zoomScale))) - 1))

                                                // Update the orbit
                                                viewModel.setPlanetOrbit(planet.id, to: targetOrbitIndex)

                                                // Reset drag state
                                                draggedPlanetID = nil
                                                dragOffset = .zero
                                            } : nil
                                    )
                            }
                        }
                    }
                }
            }
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

                Slider(value: $ringSpacing, in: 20...150, step: 5)
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

// MARK: - Simple Planet Selection Sheet

struct SimplePlanetSelectionSheet: View {
    @Environment(GalaxyViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info banner
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Select up to 10 planets to display in orbit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.sortedPlanets) { planet in
                            SimplePlanetCard(
                                planet: planet,
                                isSelected: viewModel.galaxyPlanetIDs.contains(planet.id),
                                onToggle: {
                                    viewModel.toggleGalaxy(planet)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Manage Galaxy Planets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Clear All") {
                        viewModel.galaxyPlanetIDs.removeAll()
                    }
                    .disabled(viewModel.galaxyPlanetIDs.isEmpty)
                }
            }
        }
    }
}

// MARK: - Simple Planet Card

struct SimplePlanetCard: View {
    let planet: Planet
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    PlanetView(planet: planet, size: 100, animated: false)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .background(Circle().fill(Color(uiColor: .systemBackground)))
                            .font(.title2)
                            .padding(4)
                    }
                }

                VStack(spacing: 4) {
                    Text(planet.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(planet.rarityDisplayName)
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(planet.calculatedRarity.color)
                        .cornerRadius(4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trait Row

struct TraitRow: View {
    let name: String
    let rarity: Rarity
    let isCollected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rarity indicator
            Circle()
                .fill(rarity.color)
                .frame(width: 10, height: 10)
                .opacity(isCollected ? 1.0 : 0.3)

            // Trait name
            Text(name)
                .font(.body)
                .foregroundStyle(isCollected ? .primary : .secondary)
                .opacity(isCollected ? 1.0 : 0.5)

            Spacer()

            // Rarity badge
            Text(rarity.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(rarity.color)
                .cornerRadius(4)
                .opacity(isCollected ? 1.0 : 0.5)

            // Collection status icon
            Image(systemName: isCollected ? "checkmark.circle.fill" : "lock.circle.fill")
                .foregroundStyle(isCollected ? .green : .gray)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    UnifiedPlanetView()
        .environment(GalaxyViewModel())
}
