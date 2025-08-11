//
//  ComicReaderView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/7/3.
//

import SwiftUI

struct ComicReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReadingState.self) private var reader
    @Environment(\.modelContext) private var context

    @State private var isLoading: Bool = true

    // MARK: Gesture State
    @State private var lastScale: CGFloat = 1.0
    @State private var scale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero
    @State private var anchor: UnitPoint = .center

    @State private var size: CGSize = .zero

    // MARK: Controller
    @State private var showController = false
    @State private var hideTask: Task<Void, Never>?

    // MARK: Comic Info
    var imageList: [ImageItem] {
        return reader.imageList ?? []
    }

    var chapterCount: Int {
        reader.readingComic!.chapters.count
    }

    // MARK: Gesture
    var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = value.magnification * lastScale
                anchor = value.startAnchor

                if value.magnification < 1 {
                    if scale >= 1 && lastScale != 1 {
                        let newOffsetWidth = lastDragOffset.width * (scale - 1) / (lastScale - 1)
                        let newOffsetHeight = lastDragOffset.height * (scale - 1) / (lastScale - 1)
                        dragOffset = CGSize(width: newOffsetWidth, height: newOffsetHeight)
                    } else {
                        dragOffset = .zero
                    }
                }

            }
            .onEnded { value in
                scale = max(1, min(scale, 3))
                lastScale = scale

                lastDragOffset = dragOffset
            }
    }

    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                let proposedX = lastDragOffset.width + value.translation.width
                let proposedY = lastDragOffset.height + value.translation.height

                let horizontalLeftLimit = (scale - 1) * size.width * anchor.x
                let horizontalRightLimit = (scale - 1) * size.width * (1 - anchor.x)

                let verticalTopLimit = (scale - 1) * size.height * anchor.y
                let verticalBottomLimit = (scale - 1) * size.height * (1 - anchor.y)

                let clampedX = max(-horizontalRightLimit, min(horizontalLeftLimit, proposedX))
                let clampedY = max(-verticalBottomLimit, min(verticalTopLimit, proposedY))

                dragOffset = CGSize(width: clampedX, height: clampedY)
            }
            .onEnded { _ in
                lastDragOffset = dragOffset
            }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.background)

            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(imageList, id: \.self) { image in
                                ReaderImgaeView(url: image.url)
                            }
                            Text("已经到底了!")
                                .font(.callout)
                                .padding(.vertical, 40)
                        }
                        .scrollTargetLayout()
                        .scaleEffect(scale, anchor: anchor)
                        .offset(x: dragOffset.width)
                        .animation(.easeInOut, value: scale)
                        .gesture(magnify)
                        .simultaneousGesture(drag)
                        .onTapGesture(count: 2, perform: autoScale)
                        .onTapGesture(perform: showToolbarTemporarily)
                        
                        
                    }
                    .ignoresSafeArea()
                    .background(.background)
                    .scrollIndicators(.hidden)
                    .onChange(of: reader.startReadingChapterIndex) {
                        guard reader.startReadingChapterIndex != nil else { return }
                        proxy.scrollTo(imageList.first!)
                        showToolbarTemporarily()
                    }
                    .onScrollGeometryChange(for: CGSize.self, of: { geo in geo.contentSize }) { _, newValue in
                        size = newValue
                    }
                    .onScrollTargetVisibilityChange(idType: ImageItem.self, threshold: 0.01) { items in
                        if reader.reading && items.count > 0 {
                            onVisibleImageItemChange(item: items[0])
                            Task {
                                await reader.prefetchImagesFrom(indexInList: items[items.count - 1].indexInList + 1)
                            }
                        }
                    }
                    .overlay(alignment: .topTrailing) { CloseButtonView(show: showController) }
                    .overlay(alignment: .top) { ChapterLabelView(show: showController) }
                    .overlay(alignment: .bottom) { PageLabelView(show: showController) }
                    .overlay(alignment: .bottomTrailing) { MenuButtonView(show: showController) }

                }
            }

        }
        .task {
            guard isLoading else { return }
            defer { withAnimation { isLoading = false } }
            await reader.prefetchImagesFrom(indexInList: 0, count: 7)
        }

    }

    func showToolbarTemporarily() {
        if showController {
            withAnimation { showController = false }
            hideTask?.cancel()
            hideTask = nil
            return
        }

        withAnimation { showController = true }

        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            withAnimation { showController = false }
            hideTask = nil
        }
    }

    func autoScale(point: CGPoint) {
        anchor = UnitPoint(x: point.x / size.width, y: point.y / size.height)
        if scale > 1.0 {
            scale = 1.0
            dragOffset = .zero
        } else {
            scale = 2
        }
    }

    func onVisibleImageItemChange(item: ImageItem) {
        reader.readingImageIndexInChapter = item.indexInChapter
        if reader.readingChapterIndex != item.chapterIndex {
            reader.readingChapterIndex = item.chapterIndex
            reader.syncStoredComics(context: context, chapterIndex: item.chapterIndex)
            showToolbarTemporarily()
        }
        loadNextChapterIfPossible(currentIndexInList: item.indexInList)
    }

    func loadNextChapterIfPossible(currentIndexInList: Int) {
        if currentIndexInList < imageList.count && currentIndexInList + 5 == imageList.count {
            if let nextChpaterIndex = reader.nextChapterIndex {
                if nextChpaterIndex < chapterCount {
                    reader.loadNextChapter()
                } else {
                    // TODO: inform user
                    print("Last Chapter!")
                }
            }
        }
    }

}

#Preview {
    let readingState = ReadingState()
    readingState.readingComic = ReadingComic(comic: NetworkManager.defaultComics[2], chapters: NetworkManager.defaultChapters)
    readingState.startReadingFrom(chapterIndex: 3)
    return ComicReaderView()
        .environment(readingState)
        .modelContainer(SampleStoredComic.shared.modelContainer)

}
