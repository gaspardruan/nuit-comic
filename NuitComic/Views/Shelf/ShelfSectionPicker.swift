//
//  ShelfSectionPicker.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/6.
//

import SwiftUI

struct ShelfSectionPicker: View {
    let isEditing: Bool
    @Binding var isCollectionSection: Bool
    
    var body: some View {
        Picker("选择类型", selection: $isCollectionSection) {
            Text("最近收藏").tag(true)
            Text("最近阅读").tag(false)
        }
        .pickerStyle(.segmented)
        .fixedSize()
        .disabled(isEditing)
    }
}

#Preview {
    ShelfSectionPicker(isEditing: false, isCollectionSection: Binding.constant(true))
}

#Preview("Recent") {
    ShelfSectionPicker(isEditing: false, isCollectionSection: Binding.constant(false))
}
