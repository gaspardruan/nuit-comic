//
//  Untitled.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftUI

struct SearchView: View {
    private static let debouceDuration = Duration.milliseconds(300)
    private static let previewCount = 10

    @Environment(AppState.self) private var appState

    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @State private var submitted: Bool = false
    @State private var errorMessage: String?
    @State private var results: [Comic] = []

    private var state: SearchState {
        if searchFocused { return .typing }
        if submitted { return .submitted }
        return .idle
    }

    private var showComics: [Comic] {
        submitted ? results : Array(results.prefix(Self.previewCount))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(showComics) { comic in
                    NavigationLink(destination: ComicDetailView(comic: comic)) {
                        ComicListItem(comic: comic)
                    }
                }
                if searchFocused && results.count > 10 {
                    Text("点击搜索显示所有结果")
                } else if submitted && results.count > 5 {
                    Text("到底了")
                }
            }
            .listStyle(.plain)
            .navigationTitle("搜索")
            .searchable(text: $query, prompt: "漫画名、简介、关键词、作者")
            .searchFocused($searchFocused)
            .onSubmit(of: .search) {
                submitted = true
                print("Search")
                Task {
                    await search()
                }
            }
            .onChange(of: searchFocused) { if $1 { submitted = false } }
            .task { _ = try? await appState.refreshSearchIndexIfNeeded() }
            .task(id: query) { await search() }
        }
    }

    private func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            return
        }

        errorMessage = nil
        do {
            try await Task.sleep(for: Self.debouceDuration)

            results = try await appState.searchComics(
                query: trimmedQuery, limit: searchFocused ? Self.previewCount + 1 : nil)
        } catch is CancellationError {
            return
        } catch {
            results = []
            errorMessage = error.localizedDescription
            print(errorMessage?.description ?? "")
        }

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
}
