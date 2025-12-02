//
//  ContentView.swift
//  ClastPlanetsTesting
//
//  Created by Alexander McGreevy on 11/23/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = GalaxyViewModel()

    var body: some View {
        TabView {
            GeneratorView()
                .tabItem {
                    Label("Generator", systemImage: "wand.and.stars")
                }
                .environment(viewModel)

            UnifiedPlanetView()
                .tabItem {
                    Label("Planets", systemImage: "globe.americas.fill")
                }
                .environment(viewModel)
        }
    }
}

#Preview {
    ContentView()
}
