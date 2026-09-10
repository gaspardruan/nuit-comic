//
//  ReaderState.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/26.
//

import SwiftUI

enum ReadingMode: String, CaseIterable, Identifiable {
    case vertical = "vertical"
    case horizontal = "horizontal"

    var id: Self { self }
}

@MainActor
@Observable
final class ReaderState {
    let comic: Comic
    let chapters: [Chapter]
    private let onClose: (Int) -> Void

    // Store only the current image; derive the chapter and page from it.
    private(set) var currentImage: ImageItem?
    private(set) var imageList: [ImageItem]
    private var startChapterIndex: Int

    // Each chapter jump starts a new scroll session, isolating callbacks from the previous view.
    private(set) var readingID = UUID()
    private(set) var showToolbar = false

    @ObservationIgnored private let imagePrefetcher = ReaderImagePrefetcher()
    @ObservationIgnored private var imagePixelWidth = 0
    @ObservationIgnored private var hideTask: Task<Void, Never>?

    var chapterIndex: Int {
        currentImage?.chapterIndex ?? startChapterIndex
    }

    var chapterImageCount: Int {
        chapters.isEmpty ? 0 : chapters[chapterIndex].imageList.count
    }

    init(
        comic: Comic,
        chapters: [Chapter],
        startChapterIndex: Int,
        onClose: @escaping (Int) -> Void
    ) {
        self.comic = comic
        self.chapters = chapters
        self.onClose = onClose

        // Normalize an outdated saved chapter position once when entering the reader.
        let index = chapters.indices.contains(startChapterIndex) ? startChapterIndex : 0
        self.startChapterIndex = index
        let images = generateImageItemList(
            from: chapters.isEmpty ? [] : chapters[index].imageList,
            chapterIndex: index
        )
        imageList = images
        currentImage = images.first
    }

    // MARK: - Reading events

    func start(pixelWidth: Int) {
        imagePixelWidth = pixelWidth
        if let currentImage {
            appendUpcomingChapters(near: currentImage.indexInList)
            prefetchImages(startingAt: currentImage.indexInList)
        }
        showToolbarTemporarily()
    }

    func jumpToChapter(index: Int) {
        guard chapters.indices.contains(index), index != chapterIndex else { return }

        imagePrefetcher.stop()
        startChapterIndex = index
        imageList = generateImageItemList(from: chapters[index].imageList, chapterIndex: index)
        currentImage = imageList.first
        readingID = UUID()
        start(pixelWidth: imagePixelWidth)
    }

    func visibleImagesChanged(_ images: [ImageItem], readingID: UUID) {
        // SwiftUI may call back after removing a view. Images in this session belong to imageList.
        guard self.readingID == readingID,
            let first = images.min(by: { $0.indexInList < $1.indexInList }),
            let last = images.max(by: { $0.indexInList < $1.indexInList })
        else { return }

        let previousChapter = chapterIndex
        currentImage = first
        if chapterIndex != previousChapter {
            showToolbarTemporarily()
        }

        appendUpcomingChapters(near: last.indexInList)
        prefetchImages(startingAt: last.indexInList + 1)
    }

    func close() {
        stopPrefetching()
        hideToolbar()
        onClose(chapterIndex)
    }

    func stopPrefetching() {
        imagePixelWidth = 0
        imagePrefetcher.stop()
    }

    // MARK: - Image preparation

    private func appendUpcomingChapters(near imageIndex: Int) {
        // Append when fewer than five images remain ahead; derive the next chapter from the list.
        while imageList.count - imageIndex <= 5, let lastImage = imageList.last {
            let remainingChapters = chapters.indices.dropFirst(lastImage.chapterIndex + 1)
            guard let next = remainingChapters.first(where: { !chapters[$0].imageList.isEmpty })
            else { break }

            imageList.append(
                contentsOf: generateImageItemList(
                    from: chapters[next].imageList,
                    chapterIndex: next,
                    startIndexInList: imageList.count
                ))
        }
    }

    private func prefetchImages(startingAt index: Int) {
        guard imagePixelWidth > 0 else { return }
        let urls = imageList.dropFirst(index).prefix(6).map(\.url)
        imagePrefetcher.update(urls: urls, pixelWidth: imagePixelWidth)
    }

    // MARK: - Toolbar

    func showToolbarTemporarily() {
        hideTask?.cancel()
        withAnimation { showToolbar = true }
        hideTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(3))
            } catch {
                return
            }
            self?.hideToolbar()
        }
    }

    func toggleToolbar() {
        if showToolbar {
            hideToolbar()
        } else {
            showToolbarTemporarily()
        }
    }

    private func hideToolbar() {
        hideTask?.cancel()
        hideTask = nil
        withAnimation { showToolbar = false }
    }
}

struct ImageItem: Hashable {
    let url: String
    let indexInChapter: Int
    let chapterIndex: Int
    let indexInList: Int
}
