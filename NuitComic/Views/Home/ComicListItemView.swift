//
//  ComicListItemView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import SwiftUI

struct ComicListItemView: View {
    let comic: Comic
    let hideTopSeperator: Bool
    let hideBottomSeperator: Bool

    var body: some View {
        HStack {
            RemoteImage(url: URL(string: comic.image)!) {
                phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .frame(width: 90, height: 126)
                        .cornerRadius(4)
                        .aspectRatio(5 / 7, contentMode: .fit)
                } else if phase.error != nil {
                    Color.red.frame(width: 90, height: 126)
                } else {
                    Color.gray.frame(width: 90, height: 126)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(comic.title)
                    .font(.callout)
                Text(comic.keyword)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(comic.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                Spacer()
            }
            .padding([.top], 10)
        }
        .listRowSeparator(hideTopSeperator ? .hidden : .visible, edges: .top)
        .listRowSeparator(
            hideBottomSeperator ? .hidden : .visible,
            edges: .bottom
        )

    }
}

#Preview {
    ComicListItemView(
        comic: HomeComicFetcher.defaultComics.first!,
        hideTopSeperator: true,
        hideBottomSeperator: true
    )
    .frame(maxHeight: 130)
    .border(.black)
}
