//
//  SectionView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftUI

struct SectionView<Content: View>: View {
    let comics: [Comic]
    let header: () -> Content

    private let columnNum = 3

    @State private var showDetail = false

    @Environment(ReadingState.self) private var reader

    var body: some View {
        VStack(alignment: .leading) {
            header()
            SimpleGrid(comics: comics, columnNum: columnNum) { comic, _ in
                NavigationLink(
                    destination: ComicDetailView(comic: comic)
                ) {
                    SectionItemView(comic: comic)
                }
            }
        }
        .padding(20)
    }
}

#Preview {
    ScrollView {
        SectionView(comics: NetworkManager.defaultComics) {
            Text("Header")
        }
    }
    .environment(ReadingState())
}
