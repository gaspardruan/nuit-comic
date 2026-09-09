//
//  PageLable.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/28.
//

import SwiftUI

struct PageLabel: View {
    @Environment(ReaderState.self) private var state

    var body: some View {
        if state.showToolbar, let currentImage = state.currentImage {
            Text(
                localizedFormat(
                    "reader.pagePosition",
                    currentImage.indexInChapter + 1,
                    state.chapterImageCount
                )
            )
            .font(.footnote)
            .fontWeight(.semibold)
            .padding(.horizontal, AppSpacing.tight)
            .padding(.vertical, AppSpacing.tight)
            .background(Capsule().fill(.ultraThinMaterial))
        }
    }
}
