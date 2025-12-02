//
//  ClastPlanetsTestingApp.swift
//  ClastPlanetsTesting
//
//  Created by Alexander McGreevy on 11/23/25.
//

import SwiftUI

@main
struct ClastPlanetsTestingApp: App {
    @State private var viewModel = GalaxyViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(viewModel)
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            GeneratorView()
                .tabItem {
                    Label("Generator", systemImage: "wand.and.stars")
                }

            UnifiedPlanetView()
                .tabItem {
                    Label("Planets", systemImage: "globe.americas.fill")
                }

        }
    }
}
