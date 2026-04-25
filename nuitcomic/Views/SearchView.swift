//
//  Untitled.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/22.
//

import SwiftData
import SwiftUI

struct SearchView: View {
    private static let debouceDuration = Duration.milliseconds(300)
    private static let previewCount = 10

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context

    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @State private var isPresented: Bool = false
    @State private var errMessage: String?
    @State private var showErrorAlert: Bool = false
    @State private var results: [Comic] = []

    @State private var showInfoModal = false

    private var submitted: Bool {
        isPresented && !searchFocused
    }

    private var showComics: [Comic] {
        submitted ? results : Array(results.prefix(Self.previewCount))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(showComics) { comic in
                    NavigationLink(destination: ComicDetailView(comic: comic)) {
                        ComicListItem(comic: comic, highlightQuery: query)
                    }
                }
                if searchFocused && results.count > 10 {
                    Text("search.previewHint")
                } else if submitted && results.count > 5 {
                    Text("search.end")
                }
            }
            .listStyle(.plain)
            .navigationTitle("search.title")
            .searchable(text: $query, isPresented: $isPresented, prompt: "search.prompt")
            .searchFocused($searchFocused)
            .onSubmit(of: .search, handleSubmit)
            .task { _ = try? await appState.refreshSearchIndexIfNeeded() }
            .task(id: query) { await search() }
            .overlay {
                if !isPresented {
                    SearchHistoryList(onClick: handleHistoryClick)
                }
            }
            .alert(
                "common.error", isPresented: $showErrorAlert,
                actions: { Button("common.ok") {} }
            ) {
                Text(errMessage ?? String(localized: "common.unknownError"))
            }
            .toolbar {
                ToolbarItem {
                    Button("search.about", systemImage: "info.circle") {
                        showInfoModal = true
                    }
                }
            }
            .sheet(isPresented: $showInfoModal) {
                AboutView()
            }
        }
    }

    private func handleHistoryClick(history: String) {
        query = history
        isPresented = true
        searchFocused = false
        Task { await search() }
    }

    private func handleSubmit() {
        Task { await search() }
        addSearchHistory()
    }

    private func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            return
        }

        errMessage = nil
        do {
            try await Task.sleep(for: Self.debouceDuration)

            results = try await appState.searchComics(
                query: trimmedQuery, limit: searchFocused ? Self.previewCount + 1 : nil)
        } catch is CancellationError {
            return
        } catch {
            results = []
            errMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func addSearchHistory() {
        guard !query.isEmpty else { return }

        let descriptor = FetchDescriptor<SearchHistory>(
            sortBy: [SortDescriptor(\.time, order: .reverse)]
        )

        guard let histories = try? context.fetch(descriptor) else { return }

        if let h = histories.first(where: { $0.text == query }) {
            h.time = .now
            return
        }

        if histories.count == 4 {
            context.delete(histories.last!)
        }

        context.insert(SearchHistory(text: query, time: .now))
    }
}

private enum SearchState {
    case idle
    case typing
    case submitted
}

#Preview {
    SearchView()
        .environment(AppState.defaultState)
        .modelContainer(for: SearchHistory.self)
}
