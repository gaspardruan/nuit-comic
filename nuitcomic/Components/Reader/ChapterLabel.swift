//
//  ChapterLabel.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/28.
//

import SwiftUI

struct ChapterLabel: View {
    @Environment(ReaderState.self) private var state

    var body: some View {
        if state.showToolbar {
            Text(
                localizedFormat(
                    "reader.chapterPosition",
                    state.chapterIndex + 1,
                    state.chapters.count
                )
            )
                .font(.footnote)
                .padding(.horizontal, AppSpacing.tight)
                .padding(.vertical, AppSpacing.tight)
                .background(Capsule().fill(.ultraThinMaterial))
                .shadow(radius: AppSpacing.tight)
        }
    }
}
