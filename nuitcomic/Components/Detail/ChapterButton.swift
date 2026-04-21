//
//  ChapterButton.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/25.
//

import SwiftData
import SwiftUI

struct ChapterButton: View {
    let comic: Comic

    @State private var showContent = false
    @State private var fetcher = ChapterFetcher()
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

    var lastReadChapterIndex: Int {
        sameIDComics.count > 0 ? sameIDComics[0].lastReadChapterIndex : 0
    }

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
                    focusedChapterIndex: lastReadChapterIndex
                ) { index in
                    appState.read(startChapterIndex: index)
                }
            }
        }
        .task {
            await fetcher.fetch(comicID: comic.id)
            appState.willRead(comic: comic, chapters: fetcher.chapters)
        }
    }
}

#Preview {
    ChapterButton(comic: LocalData.comics[0])
        .environment(AppState.defaultState)
        .padding()
}
