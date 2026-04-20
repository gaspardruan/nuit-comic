//
//  ComicSectionItem.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftUI

struct ComicSectionItem: View {
    let comic: Comic

    var keywords: String {
        let result = comic.keyword
            .components(separatedBy: ",")
            .prefix(2)
            .joined(separator: " ")

        return result.isEmpty ? " " : result
    }

    var body: some View {
        VStack(alignment: .leading) {
            ComicImage(url: comic.image)
                .aspectRatio(5 / 7, contentMode: .fill)
                .cornerRadius(4)

            Text(comic.title)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(keywords)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    ScrollView {
        ComicSectionItem(comic: LocalData.comics[0])
    }
}
