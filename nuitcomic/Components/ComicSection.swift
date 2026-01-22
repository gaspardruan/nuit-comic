//
//  ComicSection.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftUI

struct ComicSection<Content: View>: View {
    let comics: [Comic]
    let columnNum = 3
    let header: () -> Content


    var body: some View {
        VStack(alignment: .leading) {
            header()
            SimpleGrid(comics: comics, columnNum: columnNum) { comic, _ in
                //                NavigationLink(
                //                    destination: ComicDetailView(comic: comic)
                //                ) {
                ComicSectionItem(comic: comic)
                //                }
            }
        }
        .padding(20)
    }
}

#Preview {
    ScrollView {
        ComicSection(comics: LocalData.comics) {
            Text("Header")
        }
    }
}
