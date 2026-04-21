//
//  StoredComicStore.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/4/20.
//

import Foundation
import SwiftData

@MainActor
final class StoredComicStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func upsert(
        comic: Comic,
        lastReadChapterIndex: Int,
        chapterCount: Int
    ) {
        let comicID = comic.id
        let descriptor = FetchDescriptor<StoredComic>(
            predicate: #Predicate<StoredComic> {
                $0.id == comicID
            }
        )

        if let comics = try? context.fetch(descriptor) {
            let recentComics = comics.filter { c in
                c.isCollected == false
            }
            if !recentComics.isEmpty {
                context.delete(recentComics[0])
            }

            let collectedComics = comics.filter { c in
                c.isCollected == true
            }
            if !collectedComics.isEmpty {
                context.delete(collectedComics[0])
                context.insert(
                    StoredComic(
                        from: comic,
                        lastReadChapterIndex: lastReadChapterIndex,
                        chapterCount: chapterCount,
                        isCollected: true
                    )
                )
            }
        }

        context.insert(
            StoredComic(
                from: comic,
                lastReadChapterIndex: lastReadChapterIndex,
                chapterCount: chapterCount
            )
        )
    }

    func insert(_ comic: StoredComic) {
        context.insert(comic)
    }

    func delete(_ comic: StoredComic) {
        context.delete(comic)
    }
}
