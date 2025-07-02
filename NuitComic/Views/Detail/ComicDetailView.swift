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

    var coverHeight: CGFloat {
        (UIScreen.main.bounds.width - 2 * horizontalPadding) * 8 / 15
    }

    var body: some View {
        ScrollView {
            VStack(spacing: verticalSpace * 2) {
                BigCoverView(url: comic.cover, fallback: comic.image, height: coverHeight)

                ComicInfoView(comic: comic, spacing: verticalSpace)

                CollecAndReadView(spacing: horizontalPadding)

                ComicDescriptionView(description: comic.description)

                ChapterListButtonView(
                    comicID: comic.id, title: comic.title, updateTime: comic.updateTime, isOver: comic.isOver
                )
                .padding(.bottom, verticalSpace)

            }
            .padding(.horizontal, 20)
            .padding(.vertical, verticalSpace)

            RandomSectionView()
                .frame(maxWidth: .infinity)
                .background(.bar)
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
        ComicDetailView(comic: NetworkManager.defaultComics[0])
    }
}
