//
//  ShelfComicView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/8/4.
//

import SwiftUI

struct ShelfComicView: View {
    let active: Bool
    let chosen: Bool
    let comic: StoredComic

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomTrailing) {
                RemoteImage(url: URL(string: comic.image)!) {
                    phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(5 / 7, contentMode: .fill)
                            .cornerRadius(4)
                    } else if phase.error != nil {
                        Color.red
                            .aspectRatio(5 / 7, contentMode: .fill)
                    } else {
                        Color.gray
                            .aspectRatio(5 / 7, contentMode: .fill)
                    }
                }

                Group {
                    if active {
                        if chosen {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white, .accent)
                                .symbolRenderingMode(.palette)
                                .background(Circle().fill(.white))
                        } else {
                            Image(systemName: "inset.filled.circle")
                                .foregroundStyle(.white)
                        }
                    }
                }
                .font(.title2)
                .padding(6)

                Color.black.opacity(active && !chosen ? 0.4 : 0)
                    .cornerRadius(4)
            }
            

            Text(comic.title)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Text("\((comic.lastReadChapterIndex) + 1)/\(comic.chapterCount)章")
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .scaleEffect(active && !chosen ? 0.95 : 1)

    }
}

#Preview {

    ShelfComicView(active: false, chosen: false, comic: SampleStoredComic.defaultStoredComics[0])
        .frame(maxWidth: 150, maxHeight: 210)

}

#Preview("active") {
    ShelfComicView(active: true, chosen: false, comic: SampleStoredComic.defaultStoredComics[0])
        .frame(maxWidth: 150, maxHeight: 210)
}

#Preview("chosen") {
    ShelfComicView(active: true, chosen: true, comic: SampleStoredComic.defaultStoredComics[0])
        .frame(maxWidth: 150, maxHeight: 210)
}
