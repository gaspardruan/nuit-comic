//
//  SearchHistoryView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/7.
//

import SwiftData
import SwiftUI

struct SearchHistoryView: View {
    let searchText: String
    let onClick: (_ history: String) -> Void

    @State private var showConfirmDeletion = false

    @Environment(\.modelContext) private var context
    @Query(sort: \SearchHistory.time, order: .reverse) private var histories: [SearchHistory]

    var body: some View {
        if searchText.isEmpty && !histories.isEmpty {
            List {
                HStack {
                    Text("近期搜索记录")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()

                    Button("清除") {
                        showConfirmDeletion = true
                    }
                    .buttonStyle(.plain)
                    .font(.callout)
                }
                .listRowSeparator(.hidden, edges: .top)
                .alignmentGuide(.listRowSeparatorTrailing) { $0[.trailing] }

                ForEach(histories) { h in
                    Button(h.text, systemImage: "magnifyingglass") {
                        onClick(h.text)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                    .alignmentGuide(.listRowSeparatorTrailing) { $0[.trailing] }
                }
            }
            .listStyle(.plain)
            .confirmationDialog(Text("要删除近期搜索记录吗？"), isPresented: $showConfirmDeletion) {
                Button("清除搜索历史记录", role: .destructive, action: clearHistory)
            }
        }

    }

    private func clearHistory() {
        for h in histories {
            context.delete(h)
        }
    }
}

#Preview {
    SearchHistoryView(searchText: "mm", onClick: { h in })
        .modelContainer(for: SearchHistory.self)
}
