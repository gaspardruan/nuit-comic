//
//  ShelfListItemView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/8/6.
//

import SwiftUI

struct ShelfListItemView: View {
    let comic: StoredComic
    
    var keywords: String {
        comic.keyword.components(separatedBy: ",").prefix(2).joined(
            separator: " "
        )
    }
    
    var body: some View {
        HStack {
            RemoteImage(url: URL(string: comic.image)!) {
                phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .frame(width: 65, height: 91)
                        .cornerRadius(4)
                        .aspectRatio(5 / 7, contentMode: .fit)
                } else if phase.error != nil {
                    Color.red.frame(width: 60, height: 84)
                } else {
                    Color.gray.frame(width: 60, height: 84)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(comic.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(keywords)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text("\((comic.lastReadChapterIndex) + 1)/\(comic.chapterCount)章")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ShelfListItemView(comic: SampleStoredComic.defaultStoredComics[0])
        .frame(maxHeight: 130)
        .border(.black)
}
