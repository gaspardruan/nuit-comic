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

    @State private var scale: CGFloat = 1.0
    //    @state private var pos: ScrollPosition

    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    var imageList: [String] {
        reader.imageList ?? []
    }

    var body: some View {
        ScrollView(.horizontal) {
            ScrollView(.vertical) {
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

                    }

                }
                .frame(width: UIScreen.main.bounds.width)
                .animation(.easeInOut, value: scale)

                .gesture(
                    
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { value in
                            withAnimation {
                                scale = min(max(value, 1.0), 3.0)
                            }
                        }
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

            
            .frame(width: screenWidth * scale)
            .scaleEffect(scale)

        }
        .ignoresSafeArea()
        .scrollTargetLayout()
        .background(.background)

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
