//
//  ComicList.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/24.
//

import SwiftUI

struct ComicList: View {
    let comics: [Comic]
    let onReachBottom: () -> Void
    let threshold = 5

    var body: some View {
        List {
            ForEach(Array(comics.enumerated()), id: \.element.id) {
                index,
                comic in
                NavigationLink(
                    destination: ComicDetailView(comic: comic)
                ) {
                    ComicListItem(comic: comic)
//                        .listRowSeparator(.hidden, edges: .top)
//                        .listRowSeparator(.visible, edges: .bottom)
                        .onAppear {
                            if index == comics.count - threshold {
                                onReachBottom()
                            }
                        }
                }

            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ComicList(comics: LocalData.comics, onReachBottom: { print("reach bottom") })
    }
}
