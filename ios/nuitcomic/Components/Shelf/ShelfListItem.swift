//
//  ShelfListItem.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/30.
//

import SwiftUI

struct ShelfListItem: View {
    let comic: StoredComic

    var keywords: String {
        comic.keyword.components(separatedBy: ",").prefix(2).joined(
            separator: " "
        )
    }

    var body: some View {
        HStack {
            ComicImage(url: comic.image)
                .aspectRatio(5 / 7, contentMode: .fit)
                .cornerRadius(4)
                .frame(maxHeight: 100)
                .shadow(radius: 4, y: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(comic.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(keywords)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(
                    localizedFormat(
                        "shelf.progress",
                        comic.lastReadChapterIndex + 1,
                        comic.chapterCount
                    )
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ShelfListItem(comic: SampleStoredComic.defaultStoredComics[0])
        .border(.red)
}
