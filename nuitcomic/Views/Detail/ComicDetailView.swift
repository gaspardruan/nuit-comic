//
//  ComicDetailView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/25.
//

import SwiftUI

struct ComicDetailView: View {
    let comic: Comic

    //    @Environment(ReaderState.self) private var reader

    var coverHeight: CGFloat {
        (UIScreen.main.bounds.width - 2 * AppSpacing.standard) * 8 / 15
    }

    var body: some View {
        let _ = Self._printChanges()
        ScrollView {
            VStack(spacing: AppSpacing.tight * 2) {
                ComicImage(url: comic.cover, fallbackUrl: comic.image)
                    .scaledToFit()
                    .cornerRadius(6)
                    .frame(height: coverHeight)
                    .shadow(radius: 4, y: 4)

                Brief(comic: comic)

                CollectAndRand(
                    isCollected: true,
                    lastReadChapterIndex: 3,
                    toggleCollect: { print("toggle collect") },
                    clickRead: { print("click read") }
                )

                ExpandableDescription(
                    description: comic.description,
                    title: comic.title
                )

                ChapterButton(
                    comic: comic,
                    lastReadChapterIndex: 3
                )

            }
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.tight)

            RandomComicSection()
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
    }
}

#Preview {
    NavigationStack {
        ComicDetailView(comic: LocalData.comics[2])
            .environment(AppState())
    }
}
