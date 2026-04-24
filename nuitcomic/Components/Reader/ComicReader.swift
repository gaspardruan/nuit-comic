//
//  ComicReader.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import SwiftUI

struct ComicReader: View {
    @State private var state: ReaderState
    let screenWidth = UIScreen.main.bounds.width

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
        let _ = Self._printChanges()
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
                .overlay(alignment: .bottomLeading) { ReadingModeButton() }
                .overlay(alignment: .bottomTrailing) { ContentButton() }
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private var readerContent: some View {
        switch state.readingMode {
        case .vertical:
            verticalReader
        case .horizontal:
            horizontalReader
        }
    }

    private var verticalReader: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(state.imageList, id: \.self) { image in
                    ReaderComicImage(url: image.url)
                }
                Text("已经到底了!")
                    .padding(.vertical, 40)
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .onScrollTargetVisibilityChange(idType: ImageItem.self, threshold: 0.01) { items in
            handlScrollTargetVisibilityChange(items: items)
        }
    }

    private var horizontalReader: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(state.imageList, id: \.self) { image in
                    ReaderComicImage(url: image.url)
                        .frame(width: screenWidth)
                }
                Text("已经到底了!")
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .onScrollTargetVisibilityChange(idType: ImageItem.self, threshold: 0.5) { items in
            handlScrollTargetVisibilityChange(items: items)
        }
    }

    private func handlScrollTargetVisibilityChange(items: [ImageItem]) {
        guard items.count > 0 else { return }

        let first = items[0]
        let last = items[items.count - 1]

        state.mayLoadNextChapter(imageIndex: first.indexInList)
        state.mayUpdateImageIndex(index: first.indexInList)
        state.mayUpdateChapterIndex(index: first.chapterIndex)
        state.prefetchImagesFrom(index: last.indexInList + 1)
    }
}

struct ReaderComicImage: View {
    let url: String
    var body: some View {
        ComicImage(url: url) {
            Image("placeholder")
                .resizable()
                .scaledToFit()
                .padding(100)
                .frame(height: UIScreen.main.bounds.width / 0.618)
        }
        .scaledToFit()

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
