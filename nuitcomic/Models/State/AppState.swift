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

    init(storedComicStore: StoredComicStore) {
        self.storedComicStore = storedComicStore
    }

    var readingContext: ReadingContext?

    func read(
        comic: Comic,
        chapters: [Chapter],
        startChapterIndex: Int,
    ) {
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

    func close() {
        withAnimation {
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
