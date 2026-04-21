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
    @Environment(AppState.self) private var appState
    //    @State private var fetcher = ChapterFetcher()

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

                CollectAndRead(comic: comic)

                ExpandableDescription(
                    description: comic.description,
                    title: comic.title
                )

                ChapterButton(comic: comic)

            }
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.tight)

            RandomComicSection()
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
        .onDisappear(perform: appState.willNotRead)
    }
}

#Preview {
    NavigationStack {
        ComicDetailView(comic: LocalData.comics[2])
            .environment(AppState.defaultState)
    }
}
