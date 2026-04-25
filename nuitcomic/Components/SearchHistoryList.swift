//
//  SearchHistoryList.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/4/23.
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
                    Text("search.history.title")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()

                    Button("search.history.clear") {
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
                "search.history.confirmTitle",
                isPresented: $showConfirmDeletion,
                actions: {
                    Button("search.history.confirmAction", role: .destructive, action: clearHistory)
                }
            ) {
                Text("search.history.confirmMessage")
            }

        } else {
            ContentUnavailableView("search.history.empty", systemImage: "magnifyingglass")
        }
    }

    private func clearHistory() {
        for h in histories {
            context.delete(h)
        }
    }
}
