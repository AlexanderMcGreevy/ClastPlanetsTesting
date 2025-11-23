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
                    Label("Generator", systemImage: "sparkles")
                }
                .environment(viewModel)

            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.stack.3d.up")
                }
                .environment(viewModel)

            GalaxyView()
                .tabItem {
                    Label("Galaxy", systemImage: "globe.americas.fill")
                }
                .environment(viewModel)
        }
    }
}

#Preview {
    ContentView()
}
