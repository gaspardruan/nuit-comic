//
//  ReadingState.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import Foundation

@MainActor
@Observable
final class AppState {
    var readingContext: ReadingContext?

    func read(
        comic: Comic,
        chapters: [Chapter],
        startChapterIndex: Int,
    ) {
        readingContext = .init(
            comic: comic,
            chapters: chapters,
            startChapterIndex: startChapterIndex,
            onClose: { index in
                print("stop at \(index)")
                self.close()
            }
        )
    }

    func close() {
        readingContext = nil
    }

}

struct ReadingContext {
    let comic: Comic
    let chapters: [Chapter]
    let startChapterIndex: Int
    let onClose: (Int) -> Void
}
