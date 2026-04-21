//
//  CollectAndRand.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/25.
//

import SwiftData
import SwiftUI

struct CollectAndRead: View {
    let comic: Comic

    @Environment(AppState.self) private var appState
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

    var readButtonText: String {
        lastReadChapterIndex == 0 ? "开始阅读" : "续读\(lastReadChapterIndex + 1)章"
    }

    var collected: Bool {
        collectedComic != nil
    }

    var collectButtonText: String {
        collected ? "取消收藏" : "收藏"
    }

    var collectButtonIcon: String {
        collected ? "star.fill" : "star"
    }

    var body: some View {
        HStack(spacing: AppSpacing.loose) {
            Button {
                toggleCollect()
            } label: {
                Label(collectButtonText, systemImage: collectButtonIcon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

            Button {
                appState.read(startChapterIndex: lastReadChapterIndex)
            } label: {
                Label(readButtonText, systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

        }
        .buttonStyle(.bordered)
    }

    private func toggleCollect() {
        if collected {
            appState.unCollectComic(collectedComic!)
        } else {
            appState.collectComic(lastReadChapterIndex: lastReadChapterIndex)
        }
    }
}

#Preview {
    CollectAndRead(comic: LocalData.comics[0])
}
