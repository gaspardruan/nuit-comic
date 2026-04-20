//
//  ShelfGridItem.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/30.
//

import SwiftUI

struct ShelfGridItem: View {
    let active: Bool
    let chosen: Bool
    let comic: StoredComic

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomTrailing) {
                ComicImage(url: comic.image)
                    .aspectRatio(5 / 7, contentMode: .fill)
                    .cornerRadius(4)
                    .shadow(radius: 8, y: 8)
                Group {
                    if active {
                        if chosen {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white, .accent)
                                .symbolRenderingMode(.palette)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(Color.teal)
                        }
                    }
                }
                .background(Circle().fill(.white))
                .font(.title2)
                .padding(AppSpacing.tight)

                Color.black.opacity(active && !chosen ? 0.4 : 0)
                    .cornerRadius(4)
            }

            Text(comic.title)
                .font(.subheadline)
                .foregroundStyle(Color.primary)
                .lineLimit(1)

            Text("\((comic.lastReadChapterIndex) + 1)/\(comic.chapterCount)章")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
        }
        .scaleEffect(active && !chosen ? 0.9 : 1)
    }
}

#Preview {
    ShelfGridItem(
        active: false,
        chosen: false,
        comic: SampleStoredComic.defaultStoredComics[0]
    )
    .frame(maxWidth: 150, maxHeight: 210)
}

#Preview("active") {
    ShelfGridItem(
        active: true,
        chosen: false,
        comic: SampleStoredComic.defaultStoredComics[0]
    )
    .frame(maxWidth: 150, maxHeight: 210)
}

#Preview("chosen") {
    ShelfGridItem(
        active: true,
        chosen: true,
        comic: SampleStoredComic.defaultStoredComics[0]
    )
    .frame(maxWidth: 150, maxHeight: 210)
}
