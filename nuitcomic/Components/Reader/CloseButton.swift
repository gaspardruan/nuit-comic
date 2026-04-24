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
                Image(systemName: "xmark")
                    .fontWeight(.semibold)
                    .frame(width: 2 * AppSpacing.loose, height: 2 * AppSpacing.loose)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.loose)
        }
    }
}
