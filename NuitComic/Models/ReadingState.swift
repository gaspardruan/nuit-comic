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
    var readingImageIndexInChapter = 0

    var imageList: [ImageItem]?

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
        imageList = generateImageItemList(
            from: readingComic!.chapters[chapterIndex].imageList,
            chapterIndex: chapterIndex)
    }

    func close() {
        startReadingChapterIndex = nil
        readingChapterIndex = nil
        imageList = nil
        readingImageIndexInChapter = 0
    }
}
