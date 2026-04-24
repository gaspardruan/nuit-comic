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
    let transition: ReaderTransition?

    @Environment(AppState.self) private var appState

    var readButtonText: String {
        lastReadChapterIndex == 0
            ? String(localized: "detail.read.start")
            : localizedFormat("detail.read.continue", lastReadChapterIndex + 1)
    }

    var collected: Bool {
        collectedComic != nil
    }

    var collectButtonText: String {
        collected ? String(localized: "detail.uncollect") : String(localized: "detail.collect")
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
                    comic: comic,
                    chapters: chapters,
                    startChapterIndex: lastReadChapterIndex,
                    transition: transition
                )
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
        lastReadChapterIndex: 3,
        transition: nil
    )
}
