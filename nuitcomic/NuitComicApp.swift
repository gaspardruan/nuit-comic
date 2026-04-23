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
    @Environment(\.scenePhase) private var scenePhase

    private let appState: AppState
    private let modelContainer: ModelContainer

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
                .task {
                    _ = try? await appState.refreshSearchIndexIfNeeded()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }

                    Task {
                        _ = try? await appState.refreshSearchIndexIfNeeded()
                    }
                }
        }
    }
}
