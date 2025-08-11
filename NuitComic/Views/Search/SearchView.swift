//
//  SearchView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/6/26.
//

import SwiftData
import SwiftUI

struct SearchView: View {
    // MARK: Search State
    @State private var searcher = ComicSearcher()
    @State private var showSearchBar = false

    var showSearchState: Bool {
        !searcher.text.isEmpty && searcher.comics.isEmpty
    }

    // MARK: Search History
    @Environment(\.modelContext) private var context
    @Query(sort: \SearchHistory.time, order: .reverse) private var histories: [SearchHistory]
    
    @State private var showInfo = false

    var showNoHistoryView: Bool {
        searcher.text.isEmpty && histories.isEmpty && !showSearchBar
    }

    var body: some View {
        NavigationStack {
            List(Array(searcher.comics.enumerated()), id: \.element.id) { index, comic in
                NavigationLink(destination: ComicDetailView(comic: comic)) {
                    SearchListItemView(comic: comic)
                }
                .listRowSeparator(comic == searcher.comics.first ? .hidden : .visible, edges: .top)
                .listRowSeparator(comic == searcher.comics.last ? .hidden : .visible, edges: .bottom)
                .onAppear {
                    Task { await searcher.handleComicAppearIn(currentIndex: index) }
                }
            }
            .listStyle(.plain)
            .navigationTitle("搜索")
            .searchable(text: $searcher.text, isPresented: $showSearchBar, prompt: "漫画标题、标签、简介")
            .onChange(of: searcher.text, handleTyping)
            .onSubmit(of: .search, handleSubmit)
            .toolbar {
                ToolbarItem {
                    Button("关于", systemImage: "info.circle") {
                        showInfo = true
                    }
                }
            }
            .sheet(isPresented: $showInfo) {
                NavigationStack {
                    AboutView()
                }
            }
            .overlay {
                SearchHistoryView(searchText: searcher.text, onClick: handleClick)
            }
        }
        .overlay {
            SearchStateView(isPresented: showSearchState, isLoading: searcher.isLoading)
        }
        .overlay {
            ContentUnavailableView("搜索漫画", systemImage: "magnifyingglass")
                .opacity(showNoHistoryView ? 1 : 0)
        }
    }

    private func handleTyping() {
        searcher.resetPage()
        searcher.search()
    }

    private func handleSubmit() {
        searcher.submitted = true
        searcher.search()
        addHistory()
    }

    private func handleClick(history: String) {
        searcher.text = history
        showSearchBar = true
    }

    private func addHistory() {
        guard !searcher.text.isEmpty else { return }

        if let h = histories.first(where: { $0.text == searcher.text }) {
            h.time = .now
            return
        }
        if histories.count == 4 {
            context.delete(histories.last!)
        }
        context.insert(SearchHistory(text: searcher.text, time: .now))
    }

}

#Preview {
    SearchView()
        .environment(ReadingState())
        .modelContainer(for: SearchHistory.self)
}
