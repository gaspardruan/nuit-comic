//
//  HomeView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftUI

struct HomeView: View {
    @State private var homeComicFetcher = HomeComicFetcher()

    var body: some View {
        NavigationStack {
            Group {
                if let homeComic = homeComicFetcher.homeComic {
                    ScrollView(.vertical) {
                        VStack {
                            SectionView(
                                title: HomeSection.newComics.rawValue,
                                comics: homeComic.newComics
                            ) {
                                NavigationLink {
                                    ComicListView(section: .newComics)
                                } label: {
                                    HStack {
                                        Text(HomeSection.newComics.rawValue)
                                            .font(.title3)
                                            .fontWeight(.semibold)

                                        Image(systemName: "chevron.right")
                                    }

                                }

                            }

                            SectionView(
                                title: HomeSection.recommendedComics
                                    .rawValue,
                                comics: homeComic.recommendedComics
                            ) {
                                NavigationLink {
                                    ComicListView(section: .recommendedComics)
                                } label: {
                                    HStack {
                                        Text(
                                            HomeSection.recommendedComics
                                                .rawValue
                                        )
                                        .font(.title3)
                                        .fontWeight(.semibold)

                                        Image(systemName: "chevron.right")
                                    }

                                }

                            }
                        }
                    }

                } else {
                    ProgressView()
                }
            }
            .navigationTitle("主页")

        }
        .task {
            try? await homeComicFetcher.fetchAll()
        }

    }
}

#Preview {
    HomeView()
}
