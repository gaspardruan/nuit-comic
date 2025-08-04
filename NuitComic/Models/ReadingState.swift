//
//  ReadingState.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/3.
//

import Foundation

@Observable
class ReadingState {
    var readingComic: ReadingComic?
    var startReadingChapterIndex: Int?
    var readingChapterIndex: Int?
    var nextChapterIndex: Int?
    var readingImageIndexInChapter = 0

    var imageList: [ImageItem]?
    var imageLoaded: [Bool]?
    
    var reading: Bool {
        imageList != nil
    }

    func read(comicID: Int, title: String) async {
        var decoded: ChaptersWrapper
        do {
            let data = try await NetworkManager.shared.get(relativeURL: "/chapter_list/tp/\(comicID)-1-1-1000")
            decoded = try JSONDecoder().decode(ChaptersWrapper.self, from: data)
        } catch {
            print(error.localizedDescription)
            return
        }

        Task { @MainActor in
            readingComic = ReadingComic(title: title, chapters: decoded.result.list)
        }
    }

    func startReadingFrom(chapterIndex: Int) {
        startReadingChapterIndex = chapterIndex
        readingChapterIndex = chapterIndex
        nextChapterIndex = chapterIndex + 1
        imageList = generateImageItemList(
            from: readingComic!.chapters[chapterIndex].imageList,
            chapterIndex: chapterIndex)
        imageLoaded = Array(repeating: false, count: imageList!.count)
    }
    
    func loadNextChapter() {
        let newImageList = generateImageItemList(from: readingComic!.chapters[nextChapterIndex!].imageList, chapterIndex: nextChapterIndex!, startIndexInList: imageList!.count)
        imageList!.append(contentsOf: newImageList)
        imageLoaded!.append(contentsOf: Array(repeating: false, count: newImageList.count))
        nextChapterIndex! += 1
    }

    func close() {
        startReadingChapterIndex = nil
        readingChapterIndex = nil
        nextChapterIndex = nil
        imageList = nil
        imageLoaded = nil
        readingImageIndexInChapter = 0
    }
    
    func prefetchImagesFrom(indexInList: Int, count: Int = 5) async {
        guard  indexInList < imageList!.count else { return }

        let end = min(indexInList + count, imageList!.count)
        var slice: [String] = []
        for index in indexInList..<end {
            if !imageLoaded![index] {
                slice.append(imageList![index].url)
                imageLoaded![index] = true
            }
        }
        await NetworkManager.shared.prefetchImages(imageURLs: slice)
    }
}
