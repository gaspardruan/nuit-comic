//
//  SectionComicListView.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/24.
//

import SwiftUI

struct SectionDetailView: View {
    let section: HomeSection
    @State private var fetcher: ConditionComicFetcher

    init(section: HomeSection) {
        self.section = section
        self.fetcher = ConditionComicFetcher(section: section)
    }

    var body: some View {
        content
            .navigationTitle(section.localizedTitleKey)
            .navigationBarTitleDisplayMode(.inline)
            .task { await fetcher.firstLoad() }
    }

    @ViewBuilder
    private var content: some View {
        if !fetcher.comics.isEmpty {
            ComicList(comics: fetcher.comics, onReachBottom: loadMore)
        } else if let error = fetcher.errorMessage {
            ContentUnavailableView(
                label: { Text("home.loadFailed") },
                description: { Text(error) },
                actions: { Button("common.retry", action: loadMore) }
            )
        } else {
            ProgressView("home.loading")
        }
    }

    private func loadMore() {
        Task { await fetcher.loadMore() }
    }
}

#Preview {
    NavigationStack {
        SectionDetailView(section: .newComics)
    }
}
