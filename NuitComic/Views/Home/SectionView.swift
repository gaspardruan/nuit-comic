//
//  SectionView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftUI

struct SectionView<Content: View>: View {
    let title: String
    let comics: [Comic]
    let header: () -> Content

    private let columnNum = 3

    private let space: CGFloat = 12

    var chunkedComics: [[Comic]] {
        stride(from: 0, to: comics.count, by: columnNum).map { index in
            let end = index.advanced(by: columnNum)
            return Array(comics[index..<min(end, comics.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            header()
            Grid(horizontalSpacing: space, verticalSpacing: space) {
                ForEach(Array(chunkedComics.enumerated()), id: \.offset) {
                    _,
                    row in
                    GridRow {
                        ForEach(row) { comic in
                            NavigationLink(
                                destination: ComicDetailView(comic: comic)
                            ) {
                                SectionItemView(comic: comic)
                            }

                        }
                    }
                }
            }
        }
        .padding(20)
    }
}
