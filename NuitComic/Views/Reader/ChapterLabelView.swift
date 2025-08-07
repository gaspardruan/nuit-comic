//
//  ChapterLabelView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/7/6.
//

import SwiftUI

struct ChapterLabelView: View {
    let show: Bool
    @Environment(ReadingState.self) private var reader
    
    var chapterCount: Int {
        reader.readingComic!.chapters.count
    }
    
    var body: some View {
        Group {
            if show {
                Text("\((reader.readingChapterIndex ?? -1) + 1)/\(chapterCount)章")
                    .font(.footnote)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .shadow(radius: 8)
            }
        }
    }
}

#Preview {
    let readingState = ReadingState()
    readingState.readingComic = ReadingComic(comic: NetworkManager.defaultComics[2], chapters: NetworkManager.defaultChapters)
    readingState.startReadingFrom(chapterIndex: 3)
    return ChapterLabelView(show: true)
        .environment(readingState)
}
