//
//  ReaderState.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import SwiftUI

enum ReadingMode: String, CaseIterable, Identifiable {
    case vertical = "vertical"
    case horizontal = "horizontal"

    var id: Self { self }
}

@Observable
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

    var preloaded: Bool = false

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

    func preload() {
        guard !preloaded else { return }
        print("preload")
        prefetchImagesFrom(
            index: 0,
            onFinished: {
                withAnimation { self.preloaded = true }
                self.showToolbarTemporarily()
            }
        )
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
        guard imageList.indices.contains(index) else { return }
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
        hideTask?.cancel()

        if !showToolbar {
            withAnimation { showToolbar = true }
        }

        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation { showToolbar = false }
            hideTask = nil
        }
    }

    func toggleToolbar() {
        if showToolbar {
            withAnimation { showToolbar = false }
            hideTask?.cancel()
            hideTask = nil
            return
        }

        showToolbarTemporarily()
    }

    func jumptToChapter(index: Int) {
        guard chapterIndex != index else { return }

        chapterIndex = index
        nextChapterIndex = index + 1
        let imageList = generateImageItemList(
            from: chapters[index].imageList,
            chapterIndex: index
        )
        self.imageList = imageList
        imageLoaded = Array(repeating: false, count: imageList.count)

        preloaded = false
        preload()
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
