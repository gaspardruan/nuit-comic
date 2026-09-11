import Foundation

// Network and configuration doubles; ReaderState and its models are compiled from the app.
enum ServerConfig {
    static let imageBaseUrl = "https://example.invalid"
}

@main
@MainActor
struct ReaderStateRegressionTests {
    static func main() throws {
        try chapterJumpStartsAtFirstImage()
        try oldScrollEventsDoNotChangePosition()
        try shortChaptersContinueAutomatically()
        try emptyAndInvalidChapters()
        try prefetchWindowFollowsReadingPosition()
        try toolbarAndClose()
    }

    static func chapterJumpStartsAtFirstImage() throws {
        let state = try makeState(imageCounts: [40, 3])
        defer { state.close() }
        state.visibleImagesChanged([state.imageList[39]], readingID: state.readingID)
        state.jumpToChapter(index: 1)

        precondition(state.currentImage?.indexInChapter == 0)
        precondition(state.chapterIndex == 1 && state.chapterImageCount == 3)
        print(
            "PASS: chapter and page stay consistent when jumping from image 40 to a short chapter")
    }

    static func oldScrollEventsDoNotChangePosition() throws {
        let state = try makeState(imageCounts: [40, 3])
        defer { state.close() }
        let oldReadingID = state.readingID
        let oldImages = [state.imageList[20]]
        state.jumpToChapter(index: 1)
        state.jumpToChapter(index: 0)
        state.visibleImagesChanged(oldImages, readingID: oldReadingID)
        precondition(state.currentImage?.indexInChapter == 0)

        // Visibility events need not arrive sorted.
        state.visibleImagesChanged(
            [state.imageList[2], state.imageList[1]], readingID: state.readingID)
        precondition(state.currentImage?.indexInChapter == 1)
        state.visibleImagesChanged([], readingID: state.readingID)
        precondition(state.currentImage?.indexInChapter == 1)
        print(
            "PASS: stale and empty scroll events preserve position; current events follow reading order"
        )
    }

    static func shortChaptersContinueAutomatically() throws {
        let state = try makeState(imageCounts: [2, 0, 1, 2, 10])
        defer { state.close() }
        state.start(pixelWidth: 1200)
        precondition(state.imageList.count == 15)
        precondition(state.chapterIndex == 0)
        precondition(
            state.imageList.enumerated().allSatisfy { $0.offset == $0.element.indexInList })

        let nextChapterImage = state.imageList[2]
        state.visibleImagesChanged([nextChapterImage], readingID: state.readingID)
        precondition(state.chapterIndex == 2 && state.chapterImageCount == 1)
        precondition(state.currentImage?.indexInChapter == 0)

        state.visibleImagesChanged([state.imageList.last!], readingID: state.readingID)
        precondition(state.chapterIndex == 4 && state.currentImage?.indexInChapter == 9)
        print(
            "PASS: consecutive short chapters and skipped empty chapters retain correct positions")
    }

    static func emptyAndInvalidChapters() throws {
        let state = try makeState(imageCounts: [40, 0])
        defer { state.close() }
        let readingID = state.readingID
        state.jumpToChapter(index: -1)
        state.jumpToChapter(index: 2)
        state.jumpToChapter(index: 0)
        precondition(state.readingID == readingID)

        state.jumpToChapter(index: 1)
        precondition(state.currentImage == nil && state.imageList.isEmpty)
        precondition(state.chapterIndex == 1 && state.chapterImageCount == 0)
        state.jumpToChapter(index: 0)
        precondition(state.currentImage?.indexInChapter == 0)

        let invalidStart = try makeState(imageCounts: [10], startChapterIndex: 99)
        precondition(invalidStart.chapterIndex == 0 && invalidStart.currentImage != nil)
        invalidStart.close()

        let emptyBook = try makeState(imageCounts: [])
        emptyBook.start(pixelWidth: 1200)
        precondition(emptyBook.currentImage == nil && emptyBook.chapterImageCount == 0)
        emptyBook.close()
        print("PASS: empty chapters, invalid selections, and outdated saved positions")
    }

    static func prefetchWindowFollowsReadingPosition() throws {
        let state = try makeState(imageCounts: [40, 3])
        let prefetcher = ReaderImagePrefetcher.instances.last!
        state.start(pixelWidth: 1200)
        precondition(prefetcher.updates.last!.urls.count == 6)
        precondition(prefetcher.updates.last!.pixelWidth == 1200)

        state.visibleImagesChanged([state.imageList[20]], readingID: state.readingID)
        precondition(prefetcher.updates.last!.urls == Array(state.imageList[21..<27]).map(\.url))

        state.jumpToChapter(index: 1)
        precondition(prefetcher.stopCount == 1)
        precondition(prefetcher.updates.last!.urls.count == 3)
        precondition(state.currentImage?.indexInChapter == 0)

        state.start(pixelWidth: 2400)
        precondition(prefetcher.updates.last!.pixelWidth == 2400)
        state.close()
        precondition(prefetcher.stopCount == 2)
        let updateCount = prefetcher.updates.count
        state.visibleImagesChanged([state.imageList[0]], readingID: state.readingID)
        precondition(prefetcher.updates.count == updateCount)
        print(
            "PASS: prefetch follows position and display width, stops on chapter changes and close")
    }

    static func toolbarAndClose() throws {
        var closedChapter: Int?
        let state = try makeState(imageCounts: [10, 10], onClose: { closedChapter = $0 })
        state.start(pixelWidth: 1200)
        precondition(state.showToolbar)
        state.toggleToolbar()
        precondition(!state.showToolbar)
        state.toggleToolbar()
        precondition(state.showToolbar)
        state.jumpToChapter(index: 1)
        state.close()
        precondition(closedChapter == 1 && !state.showToolbar)
        print("PASS: toolbar visibility and closing preserve the current chapter")
    }

    static func makeState(
        imageCounts: [Int],
        startChapterIndex: Int = 0,
        onClose: @escaping (Int) -> Void = { _ in }
    ) throws -> ReaderState {
        let chapters = try imageCounts.enumerated().map { index, count in
            let json: [String: Any] = [
                "id": String(index + 1),
                "title": "Chapter \(index + 1)",
                "create_time": "2026-01-01 00:00:00",
                "imagelist": (0..<count).map { "/\(index)/\($0).jpg" }.joined(separator: ","),
            ]
            return try JSONDecoder().decode(
                Chapter.self, from: JSONSerialization.data(withJSONObject: json))
        }
        return ReaderState(
            comic: Comic(), chapters: chapters, startChapterIndex: startChapterIndex,
            onClose: onClose)
    }
}
