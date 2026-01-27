//
//  ReaderState.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import Foundation

@Observable
@MainActor
final class ReaderState {
    let comic: Comic
    let chapters: [Chapter]

    var chapterIndex: Int
    // possibly greater than chapterIndex 1 or more when a chapter is too short
    var nextChapterIndex: Int

    var imageIndex = 0
    var imageList: [ImageItem]
    var imageLoaded: [Bool]

    init(comic: Comic, chapters: [Chapter], startChapterIndex: Int) {
        self.comic = comic
        self.chapters = chapters
        self.chapterIndex = startChapterIndex
        self.nextChapterIndex = startChapterIndex + 1
        let imageList = generateImageItemList(
            from: chapters[startChapterIndex].imageList,
            chapterIndex: startChapterIndex
        )
        self.imageList = imageList
        self.imageLoaded = Array(repeating: false, count: imageList.count)
    }

    func prefetchImagesFrom(
        index: Int,
        count: Int = 5,
        onFinished: (() -> Void)? = nil
    ) {
        guard index < imageList.count else { return }

        let end = min(index + count, imageList.count)
        var slice: [String] = []
        for i in index..<end {
            if !imageLoaded[i] {
                slice.append(imageList[i].url)
                imageLoaded[i] = true
            }
        }

        ApiClient.shared.prefetch(urls: slice, onFinished: onFinished)
    }

    func mayUpdateChapterIndex(index: Int) {
        guard chapterIndex != index else { return }
        chapterIndex = index
    }

    func mayLoadNextChapter(imageIndex: Int) {
        guard imageIndex + 5 == imageList.count else { return }
        guard nextChapterIndex < chapters.count else { return }

        let newImageList = generateImageItemList(
            from: chapters[nextChapterIndex].imageList,
            chapterIndex: nextChapterIndex,
            startIndexInList: imageList.count
        )
        imageList.append(contentsOf: newImageList)
        imageLoaded.append(
            contentsOf: Array(repeating: false, count: newImageList.count)
        )
        nextChapterIndex += 1
    }

}

struct ImageItem: Hashable {
    let url: String
    let indexInChapter: Int
    let chapterIndex: Int
    let indexInList: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(chapterIndex * 1000 + indexInChapter)
    }
}
