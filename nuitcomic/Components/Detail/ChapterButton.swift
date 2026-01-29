//
//  ChapterButton.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/25.
//

import SwiftUI

struct ChapterButton: View {
    let comic: Comic
    let lastReadChapterIndex: Int

    @State private var showContent = false
    @State private var fetcher = ChapterFetcher()
    @Environment(AppState.self) private var appState

    var updateInfo: String {
        let d = dateFormatter.localizedString(
            for: comic.updateTime,
            relativeTo: Date()
        )
        return comic.isOver
            ? "\(fetcher.chapters.count)章·完本"
            : "连载至\(fetcher.chapters.count)章·\(d)"
    }

    var body: some View {
        let _ = Self._printChanges()
        Button {
            showContent = true
        } label: {
            HStack {
                Text("目录")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()

                HStack {
                    if fetcher.chapters.count > 0 {
                        Text(updateInfo)
                            .font(.subheadline)
                            .transition(.opacity)
                    } else if fetcher.isLoading {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 130, height: 20)
                    } else {
                        Text("加载失败")
                            .font(.subheadline)
                    }

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.secondary)
                }
            }
            .foregroundStyle(Color.primary)
        }
        .sheet(isPresented: $showContent) {
            NavigationStack {
                ChapterList(
                    comic: comic,
                    chapters: fetcher.chapters,
                    focusedChapterIndex: 100
                ) { index in
                    appState.read(
                        comic: comic,
                        chapters: fetcher.chapters,
                        startChapterIndex: index
                    )
                }
            }
        }
        .task {
            await fetcher.fetch(comicId: comic.id)
        }
    }
}

#Preview {
    ChapterButton(
        comic: LocalData.comics[0],
        lastReadChapterIndex: 3
    )
    .environment(AppState())
    .padding()
}
