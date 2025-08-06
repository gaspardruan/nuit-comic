//
//  SectionItemView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import SwiftUI

struct SectionItemView: View {
    let comic: Comic

    var keywords: String {
        comic.keyword.components(separatedBy: ",").prefix(2).joined(
            separator: " "
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
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
        SectionItemView(comic: NetworkManager.defaultComics[0])
    }
}
