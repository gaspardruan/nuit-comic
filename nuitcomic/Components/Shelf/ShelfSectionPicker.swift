//
//  ShelfSectionPicker.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/30.
//

import SwiftUI

struct ShelfSectionPicker: View {
    let diabled: Bool
    @Binding var collectionSelected: Bool
    
    var body: some View {
        Picker("选择类型", selection: $collectionSelected) {
            Text("最近收藏").tag(true)
            Text("最近阅读").tag(false)
        }
        .pickerStyle(.segmented)
        .disabled(diabled)
    }
}

#Preview {
    ShelfSectionPicker(diabled: false, collectionSelected: Binding.constant(true))
}
