//
//  PageLabelView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/7/6.
//

import SwiftUI

struct PageLabelView: View {
    let show: Bool
    
    @Environment(ReadingState.self) private var reader
    
    var currentChapterImageCount: Int {
        if let index = reader.readingChapterIndex {
            reader.readingComic!.chapters[index].imageList.count
        } else {
            0
        }
    }
    
    var body: some View {
        Group {
            if show {
                Text("\(reader.readingImageIndexInChapter + 1)/\(currentChapterImageCount)页")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
            }
        }
    }
}

#Preview {
    let readingState = ReadingState()
    readingState.readingComic = ReadingComic(comic: NetworkManager.defaultComics[2], chapters: NetworkManager.defaultChapters)
    readingState.startReadingFrom(chapterIndex: 3)
    return PageLabelView(show: true)
        .environment(readingState)
}
