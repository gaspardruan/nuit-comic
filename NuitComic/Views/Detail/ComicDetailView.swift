//
//  ComicDetailView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import ExpandableText
import SwiftUI

struct ComicDetailView: View {
    let comic: Comic

    private let horizontalPadding: CGFloat = 20
    private let verticalSpace: CGFloat = 8

    @State private var titleVisible = false

    var coverMaxHeight: CGFloat {
        (UIScreen.main.bounds.width - 2 * horizontalPadding) * 8 / 15
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

    var keywords: [String] {
        comic.keyword.components(separatedBy: ",").filter { keyword in
            !keyword.isEmpty
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: verticalSpace) {
                RemoteImage(
                    url: URL(string: comic.cover)!,
                    fallback: URL(string: comic.image)
                ) {
                    phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(6)
                            .frame(maxHeight: coverMaxHeight)
                            .padding(.vertical, verticalSpace)

                    } else if phase.error != nil {
                        Color.red
                    } else {
                        Color.gray
                    }
                }

                Text(comic.title)
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack {
                    Text("\(comic.score.formatted())")
                    StarRating(score: comic.score / 2)
                    Spacer().frame(width: 20)
                    Text("阅读指数 \(formattedViewNumber)")
                }
                .font(.footnote)
                .foregroundColor(.secondary)

                ScrollView(.horizontal) {
                    HStack {
                        Text("作者: \(comic.author)")
                        Text("|")
                        ForEach(keywords, id: \.self) { keyword in
                            Text(keyword)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color.cyan.opacity(0.3))
                                )
                        }

                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)

                ExpandableText(comic.description)
                    .font(.callout)
                    .lineLimit(4)
                    .moreButtonText("更多")
                    .moreButtonColor(.cyan)
                    .padding(.vertical, verticalSpace)

                HStack {
                    Text("目录")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    HStack {
                        Text("连载")
                            .font(.callout)
                        Image(systemName: "chevron.right")
                            .font(.callout)
                    }
                }

            }
            .padding(.horizontal, 20)
        }
        .onScrollGeometryChange(
            for: Bool.self,
            of: { geo in geo.contentOffset.y > 160 },
            action: { titleVisible = $1 }
        )
        .navigationTitle(titleVisible ? comic.title : "placeholder")
        .navigationBarTitleDisplayMode(.inline)

    }
}

#Preview {
    NavigationStack {
        ComicDetailView(comic: HomeComicFetcher.defaultComics[0])
    }
}
