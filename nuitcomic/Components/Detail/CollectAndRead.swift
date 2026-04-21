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
    let chapters: [Chapter]
    let collectedComic: StoredComic?
    let lastReadChapterIndex: Int

    @Environment(AppState.self) private var appState

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
                appState.read(
                    comic: comic, chapters: chapters, startChapterIndex: lastReadChapterIndex)
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
            appState.collectComic(
                comic: comic, chapters: chapters, lastReadChapterIndex: lastReadChapterIndex)
        }
    }
}

#Preview {
    CollectAndRead(
        comic: LocalData.comics[0],
        chapters: LocalData.chapters,
        collectedComic: nil,
        lastReadChapterIndex: 3
    )
}
