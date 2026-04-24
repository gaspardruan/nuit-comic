//
//  Untitled.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftUI

struct HomeView: View {
    @State private var fetcher = HomeComicFetcher()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("home.title")
        }
        .task {
            await fetcher.fetchAll()
        }
    }

    @ViewBuilder
    private var content: some View {
        let _ = Self._printChanges()
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
            VStack {
                Text("home.loadFailed")
                    .font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.gray)

                Button("common.retry") {
                    Task { await fetcher.fetchAll() }
                }
            }
        } else {
            ProgressView("home.loading")
        }
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
