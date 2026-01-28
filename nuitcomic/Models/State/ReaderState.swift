//
//  ReaderState.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import SwiftUI

@Observable
@MainActor
final class ReaderState {
    let comic: Comic
    let chapters: [Chapter]
    let onClose: (Int) -> Void

    var chapterIndex: Int
    // possibly greater than chapterIndex 1 or more when a chapter is too short
    var nextChapterIndex: Int

    var imageIndex = 0
    var imageList: [ImageItem]
    var imageLoaded: [Bool]

    var showToolbar = false
    private var hideTask: Task<Void, Never>?

    var imageIndexInChapter: Int {
        imageList[imageIndex].indexInChapter
    }

    var chapterImageCount: Int {
        chapters[chapterIndex].imageList.count
    }

    init(
        comic: Comic,
        chapters: [Chapter],
        startChapterIndex: Int,
        onClose: @escaping (Int) -> Void
    ) {
        self.comic = comic
        self.chapters = chapters
        self.chapterIndex = startChapterIndex
        self.nextChapterIndex = startChapterIndex + 1
        self.onClose = onClose
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

    func mayUpdateImageIndex(index: Int) {
        guard imageIndex != index else { return }
        imageIndex = index
    }

    func mayUpdateChapterIndex(index: Int) {
        guard chapterIndex != index else { return }
        chapterIndex = index
        showToolbarTemporarily()
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

    func showToolbarTemporarily() {
        if showToolbar {
            withAnimation { showToolbar = false }
            hideTask?.cancel()
            hideTask = nil
            return
        }

        withAnimation { showToolbar = true }

        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            withAnimation { showToolbar = false }
            hideTask = nil
        }
    }

    func close() {
        onClose(chapterIndex)
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
