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
    
    @Environment(ReadingState.self) private var reader

    var coverHeight: CGFloat {
        (UIScreen.main.bounds.width - 2 * horizontalPadding) * 8 / 15
    }
    
    var chapterCount: Int {
        reader.readingComic?.chapters.count ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: verticalSpace * 2) {
                BigCoverView(url: comic.cover, fallback: comic.image, height: coverHeight)

                ComicInfoView(comic: comic, spacing: verticalSpace)

                CollecAndReadView(comic: comic, chapterCount: chapterCount, spacing: horizontalPadding)

                ComicDescriptionView(description: comic.description)

                ChapterListButtonView(
                    comic: comic
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
        .navigationTitle(titleVisible ? comic.title : "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reader.readingComic = nil
            await reader.read(comic: comic, title: comic.title)
        }
        
    }
}

#Preview {
    NavigationStack {
        ComicDetailView(comic: NetworkManager.defaultComics[0])
    }
}
