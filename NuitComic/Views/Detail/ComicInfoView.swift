//
//  ComicInfoView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/7/2.
//

import SwiftUI

struct ComicInfoView: View {
    let comic: Comic
    let spacing: CGFloat

    init(comic: Comic, spacing: CGFloat = 8) {
        self.comic = comic
        self.spacing = spacing
    }

    var formattedViewNumber: String {
        if comic.view >= 10_000 {
            let value = Double(comic.view) / 10_000
            return String(format: "%.1f万", value)
        } else if comic.view >= 1_000 {
            let value = Double(comic.view) / 1_000
            return String(format: "%.1f千", value)
        } else {
            return "\(comic.view)"
        }
    }

    var keywords: String {
        comic.keyword.components(separatedBy: ",").filter { keyword in
            !keyword.isEmpty
        }.joined(separator: "·")
    }

    var body: some View {
        VStack(spacing: spacing) {
            Text(comic.title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(comic.author)
                .foregroundColor(.accent)

            HStack {
                Text("\(comic.score.formatted())")
                StarRating(score: comic.score / 2)
                Spacer().frame(width: 20)
                Text("阅读指数 \(formattedViewNumber)")
            }
            .font(.footnote)
            .foregroundColor(.secondary)

            Text(keywords)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }

    }
}

#Preview {
    ComicInfoView(comic: NetworkManager.defaultComics.first!)
}
