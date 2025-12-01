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
                    Label("Generator", systemImage: "sparkles")
                }

            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.stack.3d.up")
                }

            GalaxyView()
                .tabItem {
                    Label("Galaxy", systemImage: "globe.americas.fill")
                }

            TraitDictionaryView()
                .tabItem {
                    Label("Dictionary", systemImage: "book.closed")
                }
        }
    }
}
