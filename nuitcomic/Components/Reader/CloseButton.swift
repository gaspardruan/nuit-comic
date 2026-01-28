//
//  CloseButton.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/28.
//

import SwiftUI

struct CloseButton: View {
    @Environment(ReaderState.self) private var state

    var body: some View {
        if state.showToolbar {
            Button(action: state.close) {
                Label("Close", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .foregroundStyle(.mint, .ultraThinMaterial)
                    .symbolRenderingMode(.palette)
                    .padding(.horizontal, AppSpacing.standard)
                    .padding(.bottom, AppSpacing.standard)

            }
            .padding(.trailing, AppSpacing.standard)
        }
    }
}
