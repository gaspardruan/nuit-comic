//
//  PageLable.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/28.
//

import SwiftUI

struct PageLabel: View {
    @Environment(ReaderState.self) private var state

    var body: some View {
        if state.showToolbar {
            Text("\(state.imageIndexInChapter + 1)/\(state.chapterImageCount)页")
                .font(.footnote)
                .fontWeight(.semibold)
                .padding(.horizontal, AppSpacing.tight)
                .padding(.vertical, AppSpacing.tight)
                .background(Capsule().fill(.ultraThinMaterial))
        }
    }
}
