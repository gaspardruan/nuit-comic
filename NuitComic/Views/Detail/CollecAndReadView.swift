//
//  CollecAndReadView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import SwiftData
import SwiftUI

struct CollecAndReadView: View {
    let comic: Comic
    let chapterCount: Int
    let spacing: CGFloat

    @Environment(\.modelContext) private var context
    @Query private var storedComics: [StoredComic]

    @Environment(ReadingState.self) private var reader

    init(comic: Comic, chapterCount: Int, spacing: CGFloat = 20) {
        self.comic = comic
        self.spacing = spacing
        self.chapterCount = chapterCount
    }

    var sameIdComics: [StoredComic] {
        var theComics = storedComics.filter { c in
            c.id == comic.id
        }
        theComics.sort { lhs, rhs in
            lhs.storeTime > rhs.storeTime
        }
        return theComics
    }

    var collectedComic: StoredComic? {
        sameIdComics.filter { c in
            c.isCollected
        }.first
    }

    var isCollected: Bool {
        collectedComic != nil
    }

    var lastReadChapterIndex: Int {
        if sameIdComics.isEmpty {
            return 0
        }
        return sameIdComics[0].lastReadChapterIndex
    }

    var readButtonText: String {
        lastReadChapterIndex == 0 ? "开始阅读" : "续读\(lastReadChapterIndex + 1)章"
    }

    var body: some View {
        HStack(spacing: spacing) {
            Button {
                toggleCollect()
            } label: {
                Label(isCollected ? "取消收藏" : "收藏", systemImage: isCollected ? "star.fill" : "star")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

            Button {
                withAnimation {
                    reader.startReadingFrom(chapterIndex: lastReadChapterIndex)
                }
            } label: {
                Label(readButtonText, systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

        }
        .buttonStyle(.bordered)
    }

    private func toggleCollect() {
        if isCollected {
            context.delete(collectedComic!)
        } else {
            context.insert(
                StoredComic(
                    from: comic, lastReadChapterIndex: lastReadChapterIndex,
                    chapterCount: chapterCount, isCollected: true))
        }
    }
}

#Preview {
    let reader = ReadingState()
    let comic = NetworkManager.defaultComics[1]
    CollecAndReadView(comic: comic, chapterCount: 5, spacing: 20)
        .environment(reader)
        .modelContainer(SampleStoredComic.shared.modelContainer)
        .task {
            reader.readingComic = nil
            await reader.read(comic: comic, title: comic.title)
        }
}

#Preview("Not Collected") {
    let reader = ReadingState()
    let comic = NetworkManager.defaultComics[0]
    CollecAndReadView(comic: comic, chapterCount: 5, spacing: 20)
        .environment(reader)
        .modelContainer(SampleStoredComic.shared.modelContainer)
        .task {
            reader.readingComic = nil
            await reader.read(comic: comic, title: comic.title)
        }
}
