//
//  SectionComicListView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/24.
//

import SwiftUI

struct SectionDetailView: View {
    let section: HomeSection
    @State private var fetcher: SectionComicFetcher

    init(section: HomeSection) {
        self.section = section
        self.fetcher = SectionComicFetcher(section: section)
    }

    var body: some View {
        content
            .navigationTitle(section.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await fetcher.firstLoad()
            }
    }

    @ViewBuilder
    private var content: some View {
        if !fetcher.comics.isEmpty {
            ComicList(comics: fetcher.comics) {
                Task {
                    await fetcher.loadMore()
                }
            }
        } else if let error = fetcher.errorMessage {
            VStack {
                Text("加载失败")
                    .font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.gray)

                Button("重试") {
                    Task { await fetcher.loadMore() }
                }
            }
        } else {
            ProgressView("加载中...")
        }
    }
}

#Preview {
    NavigationStack {
        SectionDetailView(section: .newComics)
    }
}
