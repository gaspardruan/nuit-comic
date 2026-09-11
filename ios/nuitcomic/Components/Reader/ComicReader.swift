//
//  ComicReader.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/26.
//

import Kingfisher
import SwiftUI

struct ComicReader: View {
    @State private var state: ReaderState
    @Environment(\.displayScale) private var displayScale

    @AppStorage("readerMode") private var readingModeRaw: String = ReadingMode.vertical.rawValue
    private var readingMode: ReadingMode {
        ReadingMode(rawValue: readingModeRaw) ?? .horizontal
    }
    private var readingModeBinding: Binding<ReadingMode> {
        Binding(get: { readingMode }, set: { readingModeRaw = $0.rawValue })
    }

    init(
        comic: Comic,
        chapters: [Chapter],
        startChapterIndex: Int,
        onClose: @escaping (Int) -> Void
    ) {
        state = ReaderState(
            comic: comic,
            chapters: chapters,
            startChapterIndex: startChapterIndex,
            onClose: onClose
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let pixelWidth = max(1, Int(ceil(geometry.size.width * displayScale)))
            readerContent(width: geometry.size.width, pixelWidth: pixelWidth)
                .id(state.readingID)
                .task(id: pixelWidth) { state.start(pixelWidth: pixelWidth) }
        }
        .ignoresSafeArea()
        .onTapGesture(perform: state.toggleToolbar)
        .overlay(alignment: .topTrailing) { CloseButton() }
        .overlay(alignment: .top) { ChapterLabel() }
        .overlay(alignment: .bottom) { PageLabel() }
        .overlay(alignment: .bottomLeading) {
            ReadingModeButton(readingMode: readingModeBinding)
        }
        .overlay(alignment: .bottomTrailing) { ContentButton() }
        .environment(state)
        .onDisappear { state.stopPrefetching() }
    }

    @ViewBuilder
    private func readerContent(width: CGFloat, pixelWidth: Int) -> some View {
        switch readingMode {
        case .vertical:
            verticalReader(width: width, pixelWidth: pixelWidth)
        case .horizontal:
            horizontalReader(width: width, pixelWidth: pixelWidth)
        }
    }

    private func verticalReader(width: CGFloat, pixelWidth: Int) -> some View {
        let readingID = state.readingID
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(state.imageList, id: \.self) { image in
                        ReaderComicImage(
                            url: image.url,
                            pageWidth: width,
                            pixelWidth: pixelWidth
                        )
                        .id(image)
                    }
                    Text("reader.reachedEnd")
                        .padding(.vertical, 40)
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .task(id: readingMode) {
                scrollToCurrentImage(with: proxy, anchor: .top)
            }
            .onScrollTargetVisibilityChange(idType: ImageItem.self, threshold: 0.3) { items in
                state.visibleImagesChanged(items, readingID: readingID)
            }
        }
    }

    private func horizontalReader(width: CGFloat, pixelWidth: Int) -> some View {
        let readingID = state.readingID
        return ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(state.imageList, id: \.self) { image in
                        ReaderComicImage(
                            url: image.url,
                            pageWidth: width,
                            pixelWidth: pixelWidth
                        )
                        .frame(width: width)
                        .id(image)
                    }
                    Text("reader.reachedEnd")
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .task(id: readingMode) {
                scrollToCurrentImage(with: proxy, anchor: .leading)
            }
            .onScrollTargetVisibilityChange(idType: ImageItem.self, threshold: 0.5) { items in
                state.visibleImagesChanged(items, readingID: readingID)
            }
        }
    }

    private func scrollToCurrentImage(with proxy: ScrollViewProxy, anchor: UnitPoint) {
        guard let currentImage = state.currentImage else { return }
        proxy.scrollTo(currentImage, anchor: anchor)
    }
}

struct ReaderComicImage: View {
    let url: String
    let pageWidth: CGFloat
    let pixelWidth: Int
    @State private var imageSize: CGSize?
    @State private var isVisible = false

    init(url: String, pageWidth: CGFloat, pixelWidth: Int) {
        self.url = url
        self.pageWidth = pageWidth
        self.pixelWidth = pixelWidth
        // Use prefetched dimensions without reading from disk during layout.
        let cachedImage = ReaderImageLoading.cache.retrieveImageInMemoryCache(
            forKey: url, options: [.processor(ReaderImageProcessor(pixelWidth: pixelWidth))])
        _imageSize = State(initialValue: cachedImage?.size)
    }

    var body: some View {
        ZStack {
            if isVisible {
                KFImage(URL(string: url))
                    .setProcessor(ReaderImageProcessor(pixelWidth: pixelWidth))
                    .targetCache(ReaderImageLoading.cache)
                    .originalCache(ReaderImageLoading.cache)
                    .requestModifier(ServerConfig.requestModifier)
                    .loadDiskFileSynchronously(false)
                    .backgroundDecode()
                    .cancelOnDisappear(true)
                    .retry(maxCount: 2, interval: .seconds(2))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                            .scaledToFit()
                            .padding(100)
                            .frame(height: pageWidth / imageAspectRatio)
                    }
                    .onSuccess { result in imageSize = result.image.size }
                    .resizable()
                    .id(pixelWidth)
            } else {
                Color.clear
            }
        }
        .aspectRatio(imageAspectRatio, contentMode: .fit)
        .onAppear { isVisible = true }
        // Keep the aspect ratio for layout, but release the offscreen image view and its bitmap.
        .onDisappear { isVisible = false }
    }

    private var imageAspectRatio: CGFloat {
        guard let imageSize, imageSize.width > 0, imageSize.height > 0 else {
            return 0.618
        }
        return imageSize.width / imageSize.height
    }

}

#Preview {
    NavigationStack {
        ComicReader(
            comic: LocalData.comics[0],
            chapters: LocalData.chapters,
            startChapterIndex: 97
        ) { index in
            print("Finish reading chapter \(index)")
        }
    }
}

#Preview("horizontal") {
    NavigationStack {
        ComicReader(
            comic: LocalData.comics.last!,
            chapters: LocalData.chapters2,
            startChapterIndex: 1
        ) { index in
            print("Finish reading chapter \(index)")
        }
    }
}
