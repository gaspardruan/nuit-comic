//
//  SearchListItemView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/7.
//

import SwiftUI

struct SearchListItemView: View {
    let comic: Comic

    var keywords: String {
        comic.keyword.components(separatedBy: ",").prefix(4).joined(
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
                        .frame(width: 55, height: 77)
                        .cornerRadius(4)
                        .aspectRatio(5 / 7, contentMode: .fit)
                } else if phase.error != nil {
                    Color.red.frame(width: 55, height: 77)
                } else {
                    Color.gray.frame(width: 55, height: 77)
                }
            }
            .shadow(radius: 4, y: 4)
            VStack(alignment: .leading, spacing: 8) {
                Text(comic.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(comic.author)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(keywords)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SearchListItemView(comic: NetworkManager.defaultComics[2])
}
