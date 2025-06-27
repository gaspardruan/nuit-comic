//
//  ComicListView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import SwiftUI

struct ComicListView: View {
    let section: HomeSection

    var body: some View {
        List {
            Text(section.rawValue)
        }
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ComicListView(section: HomeSection.newComics)
}
