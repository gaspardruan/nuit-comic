//
//  ComicReaderView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/3.
//

import SwiftUI

struct ComicReaderView: View {
    private let screenAspectRatio = (UIScreen.main.bounds.width / UIScreen.main.bounds.height)

    @Environment(\.dismiss) private var dismiss
    @Environment(ReadingState.self) private var reader

    @State private var lastScale: CGFloat = 1.0
    @State private var scale: CGFloat = 1.0

    @State private var size: CGSize = .zero
    @State private var offset: CGPoint = .zero

    @State private var showTools = false
    @State private var hideTask: Task<Void, Never>?

    @State private var anchor: UnitPoint = .center

    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero

    var imageList: [ImageItem] {
        reader.imageList ?? []
    }

    var body: some View {

        ScrollView(scale == 1 ? .vertical : [.vertical, .horizontal]) {
            LazyVStack(spacing: 0) {
                ForEach(0..<imageList.count, id: \.self) { index in
                    RemoteImage(url: URL(string: imageList[index].url)!) {
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
            .scaleEffect(scale, anchor: anchor)
            .offset(x: dragOffset.width)
            .animation(.easeInOut, value: scale)
            .gesture(
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
                    },

            )
            .simultaneousGesture(
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
            )
            .onTapGesture(count: 2) { point in
                anchor = UnitPoint(x: point.x / size.width, y: point.y / size.height)
                print(dragOffset)
                print(anchor)
                if scale > 1.0 {
                    scale = 1.0
                    dragOffset = .zero
                } else {
                    scale = 2
                }
            }
            .onTapGesture {
                withAnimation {
                    showToolbarTemporarily()
                }
            }

        }
        .ignoresSafeArea()
        .background(.background)
        .overlay(
            alignment: .topTrailing,
            content: {
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

                    }
                    .padding(.trailing, 32)
                }
            }
        )
        .overlay(
            alignment: .top,
            content: {
                if showTools {
                    Text("23/270章")
                        .font(.footnote)
                        .background(.ultraThinMaterial)
                        .clipped()
                }
            }
        )
        .overlay(
            alignment: .bottom,
            content: {
                if showTools {
                    Text("12/24页")
                        .font(.footnote)
                        .background(.ultraThinMaterial)
                        .clipped()
                }
            }
        )
        .overlay(
            alignment: .bottomTrailing,
            content: {
                if showTools {
                    Button(action: {
                        withAnimation {
                            reader.close()
                        }
                    }) {
                        Label("Content", systemImage: "line.3.horizontal.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title)
                            .foregroundStyle(.mint, .ultraThinMaterial)
                            .symbolRenderingMode(.palette)

                    }
                    .padding(.trailing, 32)
                }
            }
        )
        .onScrollGeometryChange(for: ScrollGeometry.self, of: { geo in geo }) { _, n in
            size = n.contentSize
            offset = n.contentOffset
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

}

#Preview {
    let readingState = ReadingState()
    readingState.readingComic = ReadingComic(title: "秘密教学", chapters: NetworkManager.defaultChapters)
    readingState.startReadingFrom(chapterIndex: 3)
    return ComicReaderView()
        .environment(readingState)

}

//            .scaleEffect(scale, anchor: .init(x: anchor.x, y: (offset.y + screenHeight / 2) / size.height))
