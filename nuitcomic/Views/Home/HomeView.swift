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
                .navigationTitle("主页")
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
                    Text(HomeSection.mostSearchedComics.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                RandomComicSection()
            }

        }
        else if let error = fetcher.errorMessage {
            VStack {
                Text("加载失败")
                    .font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.gray)

                Button("重试") {
                    Task { await fetcher.fetchAll() }
                }
            }
        }
        else {
            ProgressView("加载中...")
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
                    Text(section.rawValue)
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
        .environment(AppState())
}
