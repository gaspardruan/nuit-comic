//
//  ReadingModeButton.swift
//  nuitcomic
//
//  Created by OpenAI Codex on 2026/1/30.
//

import SwiftUI

struct ReadingModeButton: View {
    @Environment(ReaderState.self) private var state

    @Binding var readingMode: ReadingMode

    private var iconName: String {
        switch readingMode {
        case .vertical:
            "arrow.up.and.down.text.horizontal"
        case .horizontal:
            "arrow.left.and.right.text.vertical"
        }
    }

    var body: some View {
        if state.showToolbar {
            Button(action: toggleReadingMode) {
                Image(systemName: iconName)
                    .fontWeight(.semibold)
                    .frame(width: 2 * AppSpacing.loose, height: 2 * AppSpacing.loose)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.loose)

        }
    }

    private func toggleReadingMode() {
        readingMode = readingMode == .vertical ? .horizontal : .vertical
        state.showToolbarTemporarily()
    }
}
