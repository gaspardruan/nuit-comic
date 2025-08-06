//
//  CollecAndReadView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import SwiftData
import SwiftUI

struct CollecAndReadView: View {
    let isCollected: Bool
    let lastReadChapterIndex: Int
    let toggleCollect: () -> Void
    var spacing: CGFloat = 20

    @Environment(ReadingState.self) private var reader


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
}

#Preview {
    let reader = ReadingState()
    let comic = NetworkManager.defaultComics[1]
    CollecAndReadView(isCollected: true, lastReadChapterIndex: 3, toggleCollect: {})
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
    CollecAndReadView(isCollected: false, lastReadChapterIndex: 4, toggleCollect: {})
        .environment(reader)
        .modelContainer(SampleStoredComic.shared.modelContainer)
        .task {
            reader.readingComic = nil
            await reader.read(comic: comic, title: comic.title)
        }
}
