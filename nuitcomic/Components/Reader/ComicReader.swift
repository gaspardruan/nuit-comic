//
//  ComicReader.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import SwiftData
import SwiftUI

struct ComicReader: View {
    @State private var state: ReaderState
    let screenWidth = UIScreen.main.bounds.width

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
        content
            .environment(state)
            .task {
                state.preload()
            }
    }

    @ViewBuilder
    private var content: some View {
        if state.preloaded {
            readerContent
                .ignoresSafeArea()
                .onTapGesture(perform: state.toggleToolbar)
                .overlay(alignment: .topTrailing) { CloseButton() }
                .overlay(alignment: .top) { ChapterLabel() }
                .overlay(alignment: .bottom) { PageLabel() }
                .overlay(alignment: .bottomLeading) {
                    ReadingModeButton(readingMode: readingModeBinding)
                }
                .overlay(alignment: .bottomTrailing) { ContentButton() }
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private var readerContent: some View {
        switch readingMode {
        case .vertical:
            verticalReader
        case .horizontal:
            horizontalReader
        }
    }

    private var verticalReader: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(state.imageList, id: \.self) { image in
                        ReaderComicImage(
                            url: image.url,
                            imageSize: state.imageSizes[image.url]
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
                handlScrollTargetVisibilityChange(items: items)
            }
        }
    }

    private var horizontalReader: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(state.imageList, id: \.self) { image in
                        ReaderComicImage(
                            url: image.url,
                            imageSize: state.imageSizes[image.url]
                        )
                            .frame(width: screenWidth)
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
                handlScrollTargetVisibilityChange(items: items)
            }
        }
    }

    private func scrollToCurrentImage(with proxy: ScrollViewProxy, anchor: UnitPoint) {
        guard state.imageList.indices.contains(state.imageIndex) else { return }
        let currentImage = state.imageList[state.imageIndex]

        Task { @MainActor in
            proxy.scrollTo(currentImage, anchor: anchor)
        }
    }

    private func handlScrollTargetVisibilityChange(items: [ImageItem]) {
        guard items.count > 0 else { return }

        let first = items[0]
        let last = items[items.count - 1]

        state.mayLoadNextChapter(imageIndex: first.indexInList)
        state.mayUpdateImageIndex(index: first.indexInList)
        state.mayUpdateChapterIndex(index: first.chapterIndex)
        state.prefetchImagesFrom(index: last.indexInList + 1, count: 15)
    }
}

struct ReaderComicImage: View {
    let url: String
    let imageSize: CGSize?

    var body: some View {
        ComicImage(
            url: url,
            placeholder: {
            Image("placeholder")
                .resizable()
                .scaledToFit()
                .padding(100)
                .frame(height: placeholderHeight)
        })
        .aspectRatio(imageAspectRatio, contentMode: .fit)
    }

    private var imageAspectRatio: CGFloat {
        guard let imageSize, imageSize.width > 0, imageSize.height > 0 else {
            return 0.618
        }
        return imageSize.width / imageSize.height
    }

    private var placeholderHeight: CGFloat {
        UIScreen.main.bounds.width / imageAspectRatio
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
