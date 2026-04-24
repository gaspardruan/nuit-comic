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
    let chapters: [Chapter]
    let lastReadChapterIndex: Int
    let isLoading: Bool
    let transition: ReaderTransition?

    @State private var showContent = false
    @Environment(AppState.self) private var appState

    var updateInfo: String {
        let d = dateFormatter.localizedString(
            for: comic.updateTime,
            relativeTo: Date()
        )
        return comic.isOver
            ? "\(chapters.count)章·完本"
            : "连载至\(chapters.count)章·\(d)"
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
                    if chapters.count > 0 {
                        Text(updateInfo)
                            .font(.subheadline)
                            .transition(.opacity)
                    } else if isLoading {
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
                    chapters: chapters,
                    focusedChapterIndex: lastReadChapterIndex
                ) { index in
                    appState.read(
                        comic: comic,
                        chapters: chapters,
                        startChapterIndex: index,
                        transition: transition
                    )
                }
            }
        }
    }
}

#Preview {
    ChapterButton(
        comic: LocalData.comics[0], chapters: LocalData.chapters, lastReadChapterIndex: 3,
        isLoading: false,
        transition: nil
    )
    .environment(AppState.defaultState)
    .padding()
}
