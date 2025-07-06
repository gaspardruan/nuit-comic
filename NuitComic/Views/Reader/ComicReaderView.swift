//
//  ComicReaderView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/3.
//

import SwiftUI

struct ComicReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReadingState.self) private var reader

    @State private var lastScale: CGFloat = 1.0
    @State private var scale: CGFloat = 1.0

    @State private var size: CGSize = .zero

    @State private var showTools = false
    @State private var hideTask: Task<Void, Never>?

    @State private var anchor: UnitPoint = .center

    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero

    @State private var showContent: Bool = false

    var imageList: [ImageItem] {
        return reader.imageList ?? []
    }

    var chapterCount: Int {
        reader.readingComic!.chapters.count
    }

    var currentChapterImageCount: Int {
        if let index = reader.readingChapterIndex {
            reader.readingComic!.chapters[index].imageList.count
        } else {
            0
        }
    }

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

    var closeButtonView: some View {
        Group {
            if showTools {
                Button(action: {
                    withAnimation {
                        reader.close()
                    }
                }) {
                    Label("Close", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .foregroundStyle(.mint, .ultraThinMaterial)
                        .symbolRenderingMode(.palette)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                }
                .padding(.trailing, 16)
            }
        }
    }

    var menuButtonView: some View {
        Group {
            if showTools {
                Button(action: {
                    withAnimation {
                        showContent = true
                    }
                }) {
                    Label("Content", systemImage: "line.3.horizontal.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .foregroundStyle(.mint, .ultraThinMaterial)
                        .symbolRenderingMode(.palette)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                }
                .padding(.trailing, 16)
            }
        }
    }

    var chapterLabelView: some View {
        Group {
            if showTools {
                Text("\((reader.readingChapterIndex ?? -1) + 1)/\(chapterCount)章")
                    .font(.footnote)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .shadow(radius: 8)
            }
        }
    }

    var pageLabelView: some View {
        Group {
            if showTools {
                Text("\(reader.readingImageIndexInChapter + 1)/\(currentChapterImageCount)页")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(imageList, id: \.self) { image in
                        RemoteImage(url: URL(string: image.url)!) {
                            phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()

                            } else if phase.error != nil {
                                Color.red
                                    .aspectRatio(0.618, contentMode: .fill)
                            } else {
                                Color.gray
                                    .aspectRatio(0.618, contentMode: .fill)
                            }
                        }
                        .frame(width: screenWidth)
                    }

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
            .onChange(of: reader.startReadingChapterIndex) {
                guard reader.startReadingChapterIndex != nil else { return }
                proxy.scrollTo(imageList.first!)
                showToolbarTemporarily()
            }
            .onScrollGeometryChange(for: CGSize.self, of: { geo in geo.contentSize }) { _, newValue in
                size = newValue
            }
            .onScrollTargetVisibilityChange(idType: ImageItem.self, threshold: 0.01) { items in
                if items.count > 0 {
                    onVisibleImageItemChange(item: items[0])
                }
            }
            .overlay(alignment: .topTrailing) { closeButtonView }
            .overlay(alignment: .top) { chapterLabelView }
            .overlay(alignment: .bottom) { pageLabelView }
            .overlay(alignment: .bottomTrailing) { menuButtonView }
            .sheet(isPresented: $showContent) {
                NavigationStack {
                    ChapterListView(
                        title: reader.readingComic!.title, chapters: reader.readingComic!.chapters,
                        focusedChapterIndex: reader.readingChapterIndex!, showContent: $showContent)
                }

            }
        }

    }

    func showToolbarTemporarily() {
        if showTools {
            withAnimation {
                showTools = false
            }
            hideTask?.cancel()
            hideTask = nil
            return
        }

        withAnimation {
            showTools = true
        }

        hideTask?.cancel()

        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            withAnimation {
                showTools = false
            }
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
            showToolbarTemporarily()
        }
        loadNextChapterIfPossible(currentIndexInList: item.indexInList)
    }
    
    func loadNextChapterIfPossible(currentIndexInList: Int) {
        if currentIndexInList < imageList.count && currentIndexInList + 5 == imageList.count {
            if let nextChpaterIndex = reader.nextChapterIndex{
                if nextChpaterIndex < chapterCount {
                    reader.loadNextChapter()
                } else {
                    print("Last Chapter!")
                }
            }
        }
    }

}

#Preview {
    let readingState = ReadingState()
    readingState.readingComic = ReadingComic(title: "秘密教学", chapters: NetworkManager.defaultChapters)
    readingState.startReadingFrom(chapterIndex: 3)
    return ComicReaderView()
        .environment(readingState)

}
