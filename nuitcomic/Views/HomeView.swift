//
//  Untitled.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/22.
//

import SwiftUI

struct HomeView: View {
    @State private var fetcher = HomeComicFetcher()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("home.title")
        }
        .task { await fetcher.fetchAll() }
    }

    @ViewBuilder
    private var content: some View {
        if let homeComic = fetcher.homeComic {
            ScrollView(.vertical) {
                NavigableSectionView(
                    section: .newComics,
                    comics: homeComic.newComics
                )
                NavigableSectionView(
                    section: .updatedComics,
                    comics: homeComic.updatedComics
                )
                NavigableSectionView(
                    section: .mostReadComics,
                    comics: homeComic.mostReadComics
                )
                NavigableSectionView(
                    section: .mostFollowedComics,
                    comics: homeComic.mostFollowedComics
                )
                NavigableSectionView(
                    section: .mostReadOverComics,
                    comics: homeComic.mostReadOverComics
                )
                NavigableSectionView(
                    section: .recommendedComics,
                    comics: homeComic.recommendedComics
                )

                ComicSection(comics: homeComic.mostSearchedComics) {
                    Text(HomeSection.mostSearchedComics.localizedTitleKey)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                RandomComicSection()
            }

        } else if let error = fetcher.errorMessage {
            ContentUnavailableView(
                label: { Text("home.loadFailed") },
                description: { Text(error) },
                actions: { Button("common.retry", action: fetchAll) }
            )
        } else {
            ProgressView("home.loading")
        }
    }

    private func fetchAll() {
        Task { await fetcher.fetchAll() }
    }
}

struct NavigableSectionView: View {
    let section: HomeSection
    let comics: [Comic]
    var body: some View {
        ComicSection(comics: comics) {
            NavigationLink {
                SectionDetailView(section: section)
            } label: {
                HStack {
                    Text(section.localizedTitleKey)
                        .font(.title2)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState.defaultState)
}
