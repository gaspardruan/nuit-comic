//
//  ComicDetailView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/25.
//

import SwiftData
import SwiftUI

struct ComicDetailView: View {
    let comic: Comic

    @Environment(AppState.self) private var appState
    @Namespace private var readerTransition
    @State private var fetcher = ChapterFetcher()
    @Query private var sameIDComics: [StoredComic]

    init(comic: Comic) {
        self.comic = comic
        let comicID = comic.id
        _sameIDComics = Query(
            filter: #Predicate<StoredComic> { item in item.id == comicID },
            sort: \.storeTime,
            order: .reverse
        )
    }

    var collectedComic: StoredComic? {
        sameIDComics.filter { c in c.isCollected }.first
    }

    var lastReadChapterIndex: Int {
        sameIDComics.count > 0 ? sameIDComics[0].lastReadChapterIndex : 0
    }

    var coverHeight: CGFloat {
        (UIScreen.main.bounds.width - 2 * AppSpacing.standard) * 8 / 15
    }

    var readerTransitionSourceID: String {
        "reader-cover-\(comic.id)"
    }

    var body: some View {
        let _ = Self._printChanges()
        let readingContext = Binding(
            get: { appState.readingContext },
            set: { appState.readingContext = $0 }
        )
        ScrollView {
            VStack(spacing: AppSpacing.tight * 2) {
                ComicImage(url: comic.cover, fallbackUrl: comic.image)
                    .scaledToFit()
                    .cornerRadius(6)
                    .frame(height: coverHeight)
                    .shadow(radius: 4, y: 4)
                    .matchedTransitionSource(id: readerTransitionSourceID, in: readerTransition)

                Brief(comic: comic)

                CollectAndRead(
                    comic: comic,
                    chapters: fetcher.chapters,
                    collectedComic: collectedComic,
                    lastReadChapterIndex: lastReadChapterIndex,
                    transition: .init(
                        sourceID: readerTransitionSourceID,
                        namespace: readerTransition
                    )
                )

                ExpandableDescription(
                    description: comic.description,
                    title: comic.title
                )

                ChapterButton(
                    comic: comic,
                    chapters: fetcher.chapters,
                    lastReadChapterIndex: lastReadChapterIndex,
                    isLoading: fetcher.isLoading,
                    transition: .init(
                        sourceID: readerTransitionSourceID,
                        namespace: readerTransition
                    )
                )

            }
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.tight)

            RandomComicSection()
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
        .fullScreenCover(item: readingContext) { context in
            ReaderView(context: context)
        }
        .task { await fetcher.fetch(comicID: comic.id) }
    }
}

#Preview {
    NavigationStack {
        ComicDetailView(comic: LocalData.comics[2])
            .environment(AppState.defaultState)
            .modelContainer(SampleStoredComic.shared.modelContainer)
    }
}
