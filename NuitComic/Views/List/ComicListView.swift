//
//  ComicListView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import SwiftUI

struct ComicListView: View {
    let section: HomeSection
    @State private var fetcher: SectionComicFetcher

    init(section: HomeSection) {
        self.section = section
        self.fetcher = SectionComicFetcher(section: section)
    }

    var body: some View {
        Group {
            if fetcher.comics.count > 0 {
                List {
                    ForEach(Array(fetcher.comics.enumerated()), id: \.element.id) { index, comic in
                        NavigationLink(
                            destination: ComicDetailView(comic: comic)
                        ) {
                            ComicListItemView(
                                comic: comic
                            )
                        }
                        .listRowSeparator(comic == fetcher.comics.first ? .hidden : .visible, edges: .top)
                        .listRowSeparator(
                            comic == fetcher.comics.last ? .hidden : .visible,
                            edges: .bottom
                        )
                        .onAppear {
                            Task {
                                await loadNextPage(currentIndex: index)
                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }

        }
        .listStyle(.plain)
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if fetcher.comics.count == 0 {
                await fetcher.loadNextPage()
            }
        }
    }

    private func loadNextPage(currentIndex: Int) async {
        guard !fetcher.isLoading && !fetcher.isFinished else { return }
        if currentIndex < fetcher.comics.count - 5 { return }

        await fetcher.loadNextPage()
    }
}

#Preview {
    NavigationStack {
        ComicListView(
            section: HomeSection.newComics
        )
    }
}
