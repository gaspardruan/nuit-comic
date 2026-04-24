//
//  ContentView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("tab.home", systemImage: "house.fill") { HomeView() }
            Tab("tab.shelf", systemImage: "books.vertical.fill") { ShelfView() }
            Tab("tab.search", systemImage: "magnifyingglass") { SearchView() }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState.defaultState)
        .modelContainer(SampleStoredComic.shared.modelContainer)
}
