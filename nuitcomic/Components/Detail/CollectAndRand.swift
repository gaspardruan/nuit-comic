//
//  CollectAndRand.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/25.
//

import SwiftUI

struct CollectAndRand: View {
    let isCollected: Bool
    let lastReadChapterIndex: Int
    let toggleCollect: () -> Void
    let clickRead: () -> Void

    var readButtonText: String {
        lastReadChapterIndex == 0 ? "开始阅读" : "续读\(lastReadChapterIndex + 1)章"
    }

    var collectButtonText: String {
        isCollected ? "取消收藏" : "收藏"
    }

    var collectButtonIcon: String {
        isCollected ? "star.fill" : "star"
    }

    var body: some View {
        HStack(spacing: AppSpacing.loose) {
            Button {
                toggleCollect()
            } label: {
                Label(collectButtonText, systemImage: collectButtonIcon)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

            Button {
                clickRead()
            } label: {
                Label(readButtonText, systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    CollectAndRand(
        isCollected: true,
        lastReadChapterIndex: 2,
        toggleCollect:{ print("collect")},
        clickRead: { print("click read")}
    )
}
