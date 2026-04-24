//
//  RamdomComicSection.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/23.
//

import SwiftUI

struct RandomComicSection: View {
    @State private var fetcher: RandomComicFetcher

    init(comics: [Comic]? = nil) {
        fetcher = RandomComicFetcher(comics: comics)
    }

    var body: some View {
        ComicSection(comics: fetcher.comics) {
            Button(action: handleTap) {
                HStack {
                    Text("random.recommend")
                        .font(.title3)
                        .foregroundColor(.primary)
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .foregroundColor(.secondary)
                }
                .fontWeight(.semibold)
            }
        }.task {
            await fetcher.firstRandom()
        }
    }

    private func handleTap() {
        Task {
            await fetcher.random()
        }
    }
}

#Preview {
    ScrollView {
        RandomComicSection(comics: LocalData.comics)
    }
}
