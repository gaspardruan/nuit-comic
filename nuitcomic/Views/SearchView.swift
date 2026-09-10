//
//  Untitled.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/22.
//

import SwiftData
import SwiftUI

struct SearchView: View {
    private static let debounceDuration = Duration.milliseconds(300)
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

    private var searchRequest: SearchRequest {
        // Refresh an unchanged query when new search data becomes available.
        SearchRequest(
            query: query,
            limit: searchFocused ? Self.previewCount + 1 : nil,
            indexUpdatedAt: appState.searchStatus?.lastSyncAt
        )
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
            .task(id: searchRequest) { await search(searchRequest) }
            .overlay {
                if !appState.hasSearchIndex {
                    if let error = appState.searchIndexError {
                        ContentUnavailableView {
                            Label("search.data.loadFailed", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(error)
                        } actions: {
                            Button("common.retry", action: retrySearchIndex)
                        }
                    } else {
                        ProgressView("search.data.loading")
                    }
                } else if !isPresented {
                    SearchHistoryList(onClick: handleHistoryClick)
                }
            }
            .safeAreaInset(edge: .top) {
                if appState.hasSearchIndex, appState.searchIndexError != nil {
                    HStack {
                        Text("search.data.updateFailed")
                            .font(.footnote)
                        Spacer()
                        Button("common.retry", action: retrySearchIndex)
                    }
                    .padding()
                    .background(.bar)
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
    }

    private func handleSubmit() {
        searchFocused = false
        addSearchHistory()
    }

    private func retrySearchIndex() {
        Task { await appState.refreshSearchIndexIfNeeded(force: true) }
    }

    private func search(_ request: SearchRequest) async {
        let trimmedQuery = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty, appState.hasSearchIndex else {
            results = []
            return
        }

        errMessage = nil
        do {
            try await Task.sleep(for: Self.debounceDuration)

            let comics = try await appState.searchComics(query: trimmedQuery, limit: request.limit)
            try Task.checkCancellation()
            results = comics
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
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

private struct SearchRequest: Equatable {
    let query: String
    let limit: Int?
    let indexUpdatedAt: Date?
}

#Preview {
    let appState = AppState.defaultState
    SearchView()
        .environment(appState)
        .modelContainer(for: SearchHistory.self)
        .task { await appState.refreshSearchIndexIfNeeded() }
}
