//
//  NuitComicApp.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/6/26.
//

import SwiftUI

@main
struct NuitComicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(ReadingState())
                .modelContainer(for: [StoredComic.self, SearchHistory.self])
        }
    }
}
