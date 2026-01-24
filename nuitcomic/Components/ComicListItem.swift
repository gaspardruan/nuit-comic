//
//  ComicListItem.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/24.
//

import SwiftUI

struct ComicListItem: View {
    let comic: Comic

    var body: some View {
        HStack {
            ComicImage(url: comic.image)
                .aspectRatio(5 / 7, contentMode: .fit)
                .cornerRadius(4)
            VStack(alignment: .leading, spacing: 8) {
                Text(comic.title)
                    .font(.subheadline)
                Text(comic.keyword)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(comic.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

        }
        .frame(maxHeight: 126)
    }
}

#Preview {
    ComicListItem(comic: LocalData.comics[0])
        .border(.black)
}
