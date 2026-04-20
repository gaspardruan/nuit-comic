//
//  ReaderView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import SwiftUI

struct ReaderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let context = appState.readingContext {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                ComicReader(
                    comic: context.comic,
                    chapters: context.chapters,
                    startChapterIndex: context.startChapterIndex,
                    onClose: context.onClose
                )
            }
        }
    }
}

#Preview {
    ReaderView()
        .environment(AppState.defaultState)
}
