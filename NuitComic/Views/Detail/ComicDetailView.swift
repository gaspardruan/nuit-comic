//
//  ComicDetailView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/6/27.
//

import ExpandableText
import SwiftData
import SwiftUI

struct ComicDetailView: View {
    let comic: Comic

    private let horizontalPadding: CGFloat = 20
    private let verticalSpace: CGFloat = 8

    @State private var titleVisible = false

    @Environment(ReadingState.self) private var reader
    @Environment(\.modelContext) private var context
    @Query private var storedComics: [StoredComic]

    var coverHeight: CGFloat {
        (UIScreen.main.bounds.width - 2 * horizontalPadding) * 8 / 15
    }

    var chapterCount: Int {
        reader.readingComic?.chapters.count ?? 0
    }

    var sameIdComics: [StoredComic] {
        var theComics = storedComics.filter { c in
            c.id == comic.id
        }
        theComics.sort { lhs, rhs in
            lhs.storeTime > rhs.storeTime
        }
        return theComics
    }

    var collectedComic: StoredComic? {
        sameIdComics.filter { c in
            c.isCollected
        }.first
    }

    var isCollected: Bool {
        collectedComic != nil
    }

    var lastReadChapterIndex: Int {
        if sameIdComics.isEmpty {
            return 0
        }
        return sameIdComics[0].lastReadChapterIndex
    }

    var body: some View {
        ScrollView {
            VStack(spacing: verticalSpace * 2) {
                BigCoverView(url: comic.cover, fallback: comic.image, height: coverHeight)

                ComicInfoView(comic: comic, spacing: verticalSpace)

                CollecAndReadView(
                    isCollected: isCollected, lastReadChapterIndex: lastReadChapterIndex,
                    toggleCollect: toggleCollect, spacing: horizontalPadding)

                ComicDescriptionView(description: comic.description)

                ChapterListButtonView(comic: comic, lastReadChapterIndex: lastReadChapterIndex)
                    .padding(.bottom, verticalSpace)

            }
            .padding(.horizontal, 20)
            .padding(.vertical, verticalSpace)

            RandomSectionView()
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
        .onScrollGeometryChange(
            for: Bool.self,
            of: { geo in geo.contentOffset.y > 160 },
            action: { titleVisible = $1 }
        )
        .navigationTitle(titleVisible ? comic.title : "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reader.readingComic = nil
            await reader.read(comic: comic, title: comic.title)
        }

    }

    private func toggleCollect() {
        if isCollected {
            context.delete(collectedComic!)
        } else {
            context.insert(
                StoredComic(
                    from: comic, lastReadChapterIndex: lastReadChapterIndex,
                    chapterCount: chapterCount, isCollected: true))
        }
    }
}

#Preview {
    NavigationStack {
        ComicDetailView(comic: NetworkManager.defaultComics[2])
            .environment(ReadingState())
            .modelContainer(SampleStoredComic.shared.modelContainer)
    }
}
