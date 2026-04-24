//
//  ContentView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        let readingContext = Binding(
            get: { appState.readingContext },
            set: { appState.readingContext = $0 }
        )
        TabView {
            Tab("主页", systemImage: "house.fill") { HomeView() }
            Tab("书架", systemImage: "books.vertical.fill") { ShelfView() }
            Tab("搜索", systemImage: "magnifyingglass") { SearchView() }
        }
//        .fullScreenCover(item: readingContext) { context in
//            ReaderView(context: context)
//        }
    }
}

#Preview {
    ContentView()
        .environment(AppState.defaultState)
        .modelContainer(SampleStoredComic.shared.modelContainer)
}
