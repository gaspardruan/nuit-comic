//
//  nuitcomicApp.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftData
import SwiftUI

@main
struct nuitcomicApp: App {
    private let modelContainer: ModelContainer
    private let appState: AppState

    init() {
        setupKingfisher()
        modelContainer = try! ModelContainer(for: StoredComic.self)
        let storedComicStore = StoredComicStore(context: modelContainer.mainContext)
        appState = AppState(storedComicStore: storedComicStore)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
    }
}
