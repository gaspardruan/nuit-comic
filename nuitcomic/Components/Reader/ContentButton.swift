//
//  MenuButton.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/28.
//

import SwiftUI

struct ContentButton: View {
    @Environment(ReaderState.self) private var state
    @State private var showContent = false

    var body: some View {
        ZStack {
            if state.showToolbar {
                Button {
                    showContent = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .fontWeight(.semibold)
                        .frame(width: 2 * AppSpacing.loose, height: 2 * AppSpacing.loose)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.loose)
            }
        }
        .sheet(isPresented: $showContent) {
            NavigationStack {
                ChapterList(
                    comic: state.comic,
                    chapters: state.chapters,
                    focusedChapterIndex: state.chapterIndex
                ) { index in
                    Task { @MainActor in
                        state.jumptToChapter(index: index)
                    }
                }
            }
        }
    }
}
