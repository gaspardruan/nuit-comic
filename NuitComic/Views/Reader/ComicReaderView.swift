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
    //    @state private var pos: ScrollPosition
    @State private var size: CGSize = .zero
    @State private var offset: CGPoint = .zero

    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    var imageList: [String] {
        reader.imageList ?? []
    }

    var body: some View {
        ScrollView(scale == 1.0 ? .vertical : [.vertical, .horizontal]) {
            VStack(spacing: 0) {
                ForEach(imageList, id: \.self) { image in
                    RemoteImage(url: URL(string: image)!) {
                        phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()

                        } else if phase.error != nil {
                            Color.red
                                .aspectRatio(1, contentMode: .fill)
                        } else {
                            Color.gray
                                .aspectRatio(1, contentMode: .fill)
                        }
                    }
                    .frame(maxWidth: screenWidth)
                }

            }
            .scaleEffect(scale, anchor: .init(x: 0.5, y: (offset.y + screenHeight / 2) / size.height))
            .frame(width: UIScreen.main.bounds.width * scale)
            .animation(.easeInOut, value: scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(value * lastScale, 1)
                    }
                    .onEnded { value in
                        scale = min(scale, 3.0)
                        lastScale = scale
                    },
                including: .gesture
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation {
                            if scale > 1.0 {
                                scale = 1.0
                            } else {
                                scale = 1.5
                            }
                        }
                    })
        }
        .ignoresSafeArea()
        .background(.background)
        .onScrollGeometryChange(for: ScrollGeometry.self, of: {geo in geo}) { _, n in
            size = n.contentSize
            offset = n.contentOffset
        }
    }

}

#Preview {
    var readingState = ReadingState()
    readingState.readingComic = ReadingComic(title: "秘密教学", chapters: NetworkManager.defaultChapters)
    readingState.read(chapterIndex: 3)
    return ComicReaderView()
        .environment(readingState)
}

//        List {
//            ForEach(imageList, id: \.self) { image in
//                RemoteImage(url: URL(string: image)!) {
//                    phase in
//                    if let image = phase.image {
//                        image
//                            .resizable()
//                            .scaledToFit()
//
//                    } else if phase.error != nil {
//                        Color.red
//                            .aspectRatio(1, contentMode: .fill)
//                    } else {
//                        Color.gray
//                            .aspectRatio(1, contentMode: .fill)
//                    }
//                }
//            }
//            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
//            .listRowSeparator(.hidden)
//
//        }
//        .listStyle(.plain)
