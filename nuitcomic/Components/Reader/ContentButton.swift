//
//  MenuButton.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/28.
//

import SwiftUI

struct ContentButton: View {
    @Environment(ReaderState.self) private var state
    @State private var showContent = false

    var body: some View {
        ZStack {
            if state.showToolbar {
                Button(action: {
                    showContent = true
                }) {
                    Label(
                        "Content",
                        systemImage: "line.3.horizontal.circle.fill"
                    )
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .foregroundStyle(.mint, .ultraThinMaterial)
                    .symbolRenderingMode(.palette)
                    .padding(.horizontal, AppSpacing.standard)
                    .padding(.top, AppSpacing.standard)

                }
                .padding(.trailing, AppSpacing.standard)

            }
        }
        .sheet(isPresented: $showContent) {
            NavigationStack {
                ChapterList(
                    comic: state.comic,
                    chapters: state.chapters,
                    focusedChapterIndex: 100
                ) { index in
                    Task { @MainActor in
                        state.jumptToChapter(index: index)
                    }
                }
            }
        }
    }
}
