//
//  ComicReader.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import SwiftUI

struct ComicReader: View {
    @State private var state: ReaderState

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
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(state.imageList, id: \.self) { image in
                        ReaderComicImage(url: image.url)
                    }
                    Text("已经到底了!")
                        .padding(.vertical, 40)
                }
                .scrollTargetLayout()
                .onTapGesture {
                    state.toggleToolbar()
                }
            }
            .ignoresSafeArea()
            .scrollIndicators(.hidden)
            .onScrollTargetVisibilityChange(
                idType: ImageItem.self,
                threshold: 0.01
            ) { items in handlScrollTargetVisibilityChange(items: items) }
            .overlay(alignment: .topTrailing) { CloseButton() }
            .overlay(alignment: .top) { ChapterLabel() }
            .overlay(alignment: .bottom) { PageLabel() }
            .overlay(alignment: .bottomTrailing) { ContentButton() }
        } else {
            ProgressView()
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
    ComicReader(
        comic: LocalData.comics[0],
        chapters: LocalData.chapters,
        startChapterIndex: 97
    ) { index in
        print("Finish reading chapter \(index)")
    }
}
