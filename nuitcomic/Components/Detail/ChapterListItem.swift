//
//  ChapterListItem.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/25.
//

import SwiftUI

struct ChapterListItem: View {
    let title: String
    let createTime: Date
    let emphasized: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(emphasized ? .bold : .semibold)
                    .foregroundStyle(emphasized ? Color.accent : Color.primary)

                Text(
                    createTime.formatted(
                        .dateTime.year().month(.twoDigits).day(.twoDigits)
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    ChapterListItem(title: "测试", createTime: Date(), emphasized: true)
}
