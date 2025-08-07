//
//  ComicListItemView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/6/27.
//

import SwiftUI

struct ComicListItemView: View {
    let comic: Comic

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
                    .font(.subheadline)
                Text(comic.keyword)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(comic.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
       

    }
}

#Preview {
    ComicListItemView(
        comic: NetworkManager.defaultComics.first!
    )
    .frame(maxHeight: 130)
    .border(.black)
}
