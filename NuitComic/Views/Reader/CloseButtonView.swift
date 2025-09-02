//
//  CloseButtonView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/7/6.
//

import SwiftUI

struct CloseButtonView: View {
    let show: Bool
    @Environment(ReadingState.self) private var reader

    var body: some View {
        Group {
            if show {
                Button(action: {
                    reader.close()
                }) {
                    Label("Close", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .foregroundStyle(.mint, .ultraThinMaterial)
                        .symbolRenderingMode(.palette)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                }
                .padding(.trailing, 16)
            }
        }
    }
}

#Preview {
    CloseButtonView(show: true)
        .environment(ReadingState())
}
