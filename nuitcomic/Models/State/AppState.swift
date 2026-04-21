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
    var willReadContext: WillRead?

    init(storedComicStore: StoredComicStore) {
        self.storedComicStore = storedComicStore
    }

    func willRead(comic: Comic, chapters: [Chapter]) {
        willReadContext = .init(comic: comic, chapters: chapters)
    }

    func read(startChapterIndex: Int) {
        guard willReadContext != nil else { return }
        let comic = willReadContext!.comic
        let chapters = willReadContext!.chapters

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

    func collectComic(lastReadChapterIndex: Int) {
        guard willReadContext != nil else { return }
        let comic = willReadContext!.comic
        let chapters = willReadContext!.chapters

        storedComicStore.insert(
            StoredComic(
                from: comic, lastReadChapterIndex: lastReadChapterIndex, chapterCount: chapters.count,
                isCollected: true
            ))
    }

    func unCollectComic(_ comic: StoredComic) {
        storedComicStore.delete(comic)
    }

    func willNotRead() {
        willReadContext = nil
    }

    func close() {
        withAnimation(.easeOut(duration: 0.22)) {
            readingContext = nil
        }
    }

}

struct WillRead {
    let comic: Comic
    let chapters: [Chapter]
}

struct ReadingContext {
    let comic: Comic
    let chapters: [Chapter]
    let startChapterIndex: Int
    let onClose: (Int) -> Void
}
