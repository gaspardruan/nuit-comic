//
//  MenuButtonView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/6.
//

import SwiftUI

struct MenuButtonView: View {
    let show: Bool
    @Environment(ReadingState.self) private var reader
    
    @State private var showContent = false
    
    var body: some View {
        Group {
            if show {
                Button(action: {
                    withAnimation {
                        showContent = true
                    }
                }) {
                    Label("Content", systemImage: "line.3.horizontal.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .foregroundStyle(.mint, .ultraThinMaterial)
                        .symbolRenderingMode(.palette)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                }
                .padding(.trailing, 16)
            }
        }
        .sheet(isPresented: $showContent) {
            NavigationStack {
                ChapterListView(
                    title: reader.readingComic!.title, chapters: reader.readingComic!.chapters,
                    focusedChapterIndex: reader.readingChapterIndex!, showContent: $showContent)
            }

        }
    }
}

#Preview {
    let readingState = ReadingState()
    readingState.readingComic = ReadingComic(title: "秘密教学", chapters: NetworkManager.defaultChapters)
    readingState.startReadingFrom(chapterIndex: 3)
    return MenuButtonView(show: true)
        .environment(readingState)
}
