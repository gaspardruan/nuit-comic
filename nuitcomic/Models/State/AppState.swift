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
    // MARK: Comic State
    var readingComic: ReadingComic?

    func readCover(comic: Comic) async {
        let chapters = await ChapterFetcher.fetch(comicId: comic.id)
        readingComic = ReadingComic(c: comic, ch: chapters)
    }

    // MARK: Comic Content State

}

struct ReadingComic {
    let c: Comic
    let ch: [Chapter]
}


