//
//  SearchStateView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/7.
//

import SwiftUI

struct SearchStateView: View {
    let isPresented: Bool
    let isLoading: Bool
    
    var body: some View {
        Text(isLoading ? "搜索中..." : "没有搜索结果")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .opacity(isPresented ? 1 : 0)
    }
}

#Preview {
    SearchStateView(isPresented: true, isLoading: true)
}
