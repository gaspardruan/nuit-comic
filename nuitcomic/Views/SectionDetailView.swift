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
        let _ = Self._printChanges()
        content
            .navigationTitle(section.localizedTitleKey)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await fetcher.firstLoad()
            }
    }

    @ViewBuilder
    private var content: some View {
        if !fetcher.comics.isEmpty {
            ComicList(comics: fetcher.comics) {
                Task {
                    await fetcher.loadMore()
                }
            }
        } else if let error = fetcher.errorMessage {
            VStack {
                Text("home.loadFailed")
                    .font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.gray)

                Button("common.retry") {
                    Task { await fetcher.loadMore() }
                }
            }
        } else {
            ProgressView("home.loading")
        }
    }
}

#Preview {
    NavigationStack {
        SectionDetailView(section: .newComics)
    }
}
