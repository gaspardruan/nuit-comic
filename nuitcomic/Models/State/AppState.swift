//
//  ReadingState.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import SwiftUI

@MainActor
@Observable
final class AppState {
    private let storedComicStore: StoredComicStore
    private let comicSearchStore: ComicSearchStore
    var readingContext: ReadingContext?

    init(storedComicStore: StoredComicStore, comicSearchStore: ComicSearchStore = .shared) {
        self.storedComicStore = storedComicStore
        self.comicSearchStore = comicSearchStore
    }

    func read(comic: Comic, chapters: [Chapter], startChapterIndex: Int) {
        storedComicStore.upsert(
            comic: comic,
            lastReadChapterIndex: startChapterIndex,
            chapterCount: chapters.count
        )

        readingContext = .init(
            comic: comic,
            chapters: chapters,
            startChapterIndex: startChapterIndex,
            onClose: { index in
                self.close()

                self.storedComicStore.upsert(
                    comic: comic,
                    lastReadChapterIndex: index,
                    chapterCount: chapters.count
                )
            }
        )
    }

    func collectComic(comic: Comic, chapters: [Chapter], lastReadChapterIndex: Int) {
        storedComicStore.insert(
            StoredComic(
                from: comic, lastReadChapterIndex: lastReadChapterIndex,
                chapterCount: chapters.count,
                isCollected: true
            ))
    }

    func unCollectComic(_ comic: StoredComic) {
        storedComicStore.delete(comic)
    }

    func close() {
        withAnimation(.easeOut(duration: 0.22)) {
            readingContext = nil
        }
    }

    func refreshSearchIndexIfNeeded() async throws -> SearchStatus {
        let status = try await comicSearchStore.status()

        if status.comicCount > 0, let lastSyncAt = status.lastSyncAt,
            Date().timeIntervalSince(lastSyncAt) < 12 * 60 * 60
        {
            return status
        }

        return try await refreshSearchIndex()
    }

    func refreshSearchIndex() async throws -> SearchStatus {
        let comics = try await ComicClient.shared.fetchAllComics()
        return try await comicSearchStore.replaceIndex(with: comics)
    }

    func searchComics(query: String, limit: Int? = nil) async throws -> [Comic] {
        try await comicSearchStore.search(query: query, limit: limit)
    }

}

struct ReadingContext {
    let comic: Comic
    let chapters: [Chapter]
    let startChapterIndex: Int
    let onClose: (Int) -> Void
}
