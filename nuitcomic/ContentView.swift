//
//  ContentView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    var body: some View {
        TabView {
            Tab("tab.home", systemImage: "house.fill") { HomeView() }
            Tab("tab.shelf", systemImage: "books.vertical.fill") { ShelfView() }
            Tab("tab.search", systemImage: "magnifyingglass") { SearchView() }
        }
        .alert(
            "update.alert.title",
            isPresented: Binding(
                get: { appState.showUpdateAlert },
                set: { isPresented in
                    if !isPresented {
                        appState.dismissUpdateAlert()
                    }
                }
            )
        ) {
            Button("update.alert.install") {
                openURL(appState.updateInstallURL)
                appState.dismissUpdateAlert()
            }
            Button("common.cancel", role: .cancel) {
                appState.dismissUpdateAlert()
            }
        } message: {
            if let update = appState.availableUpdate {
                Text(updateAlertMessage(for: update))
            }
        }
    }

    private func updateAlertMessage(for update: AppUpdateInfo) -> String {
        let base = localizedFormat("update.alert.message", update.version)
        guard !update.trimmedMessage.isEmpty else { return base }
        return "\(base)\n\n\(update.trimmedMessage)"
    }
}

#Preview {
    ContentView()
        .environment(AppState.defaultState)
        .modelContainer(SampleStoredComic.shared.modelContainer)
}
