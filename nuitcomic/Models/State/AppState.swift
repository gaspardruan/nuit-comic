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
    var readingContext: ReadingContext?

    init(storedComicStore: StoredComicStore) {
        self.storedComicStore = storedComicStore
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

}

struct ReadingContext {
    let comic: Comic
    let chapters: [Chapter]
    let startChapterIndex: Int
    let onClose: (Int) -> Void
}
