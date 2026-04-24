//
//  SearchHistoryList.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/4/23.
//

import SwiftData
import SwiftUI

struct SearchHistoryList: View {
    let onClick: (_ history: String) -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \SearchHistory.time, order: .reverse) private var histories: [SearchHistory]

    @State private var showConfirmDeletion: Bool = false

    var body: some View {
        if histories.count > 0 {
            List {
                HStack {
                    Text("近期搜索记录")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()

                    Button("清除") {
                        showConfirmDeletion = true
                    }
                    .buttonStyle(.plain)
                    .font(.callout)
                }
                .listRowSeparator(.hidden, edges: .top)

                ForEach(Array(histories.prefix(5))) { h in
                    Button(h.text, systemImage: "magnifyingglass") {
                        onClick(h.text)
                    }
                }
            }
            .listStyle(.plain)
            .confirmationDialog(
                "清除搜素历史记录", isPresented: $showConfirmDeletion,
                actions: {
                    Button("清除搜索历史记录", role: .destructive, action: clearHistory)
                }
            ) {
                Text("将会删除近期搜索记录")
            }

        } else {
            ContentUnavailableView("搜索漫画", systemImage: "magnifyingglass")
        }
    }

    private func clearHistory() {
        for h in histories {
            context.delete(h)
        }
    }
}
