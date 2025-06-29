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
                            NavigableSectionView(section: .newComics, comics: homeComic.newComics)
                            NavigableSectionView(section: .updatedComics, comics: homeComic.updatedComics)
                            NavigableSectionView(section: .mostReadComics, comics: homeComic.mostReadComics)
                            NavigableSectionView(section: .mostFollowedComics, comics: homeComic.mostFollowedComics)
                            NavigableSectionView(section: .mostReadOverComics, comics: homeComic.mostReadOverComics)
                            NavigableSectionView(section: .recommendedComics, comics: homeComic.recommendedComics)
                            
                            SectionView(comics: homeComic.mostSearchedComics) {
                                Text(HomeSection.mostSearchedComics.rawValue)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            RandomSectionView()
                            
                            
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
            print("Home!")
        }

    }
}

struct NavigableSectionView: View {
    let section: HomeSection
    let comics: [Comic]
    var body: some View {
        SectionView(comics: comics) {
            NavigationLink {
                ComicListView(section: section)
            } label: {
                HStack {
                    Text(section.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                }

            }

        }
    }
}

#Preview {
    HomeView()
}
