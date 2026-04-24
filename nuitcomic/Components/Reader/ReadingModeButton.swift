//
//  ReadingModeButton.swift
//  nuitcomic
//
//  Created by OpenAI Codex on 2026/1/30.
//

import SwiftUI

struct ReadingModeButton: View {
    @Environment(ReaderState.self) private var state

    private var iconName: String {
        switch state.readingMode {
        case .vertical:
            "rectangle.split.1x2"
        case .horizontal:
            "rectangle.split.2x1"
        }
    }

    var body: some View {
        if state.showToolbar {
            Button(action: state.toggleReadingMode) {
                Label("Reading Mode", systemImage: iconName)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.mint, .ultraThinMaterial)
                    .symbolRenderingMode(.palette)
                    .padding(.horizontal, AppSpacing.standard)
                    .padding(.top, AppSpacing.standard)
            }
            .padding(.leading, AppSpacing.standard)
        }
    }
}
