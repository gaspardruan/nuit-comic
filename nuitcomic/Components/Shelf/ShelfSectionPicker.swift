//
//  ShelfSectionPicker.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/30.
//

import SwiftUI

struct ShelfSectionPicker: View {
    let diabled: Bool
    @Binding var section: ShelfSection

    var body: some View {
        Picker("选择类型", selection: $section) {
            Text("最近收藏").tag(ShelfSection.collection)
            Text("最近阅读").tag(ShelfSection.recent)
        }
        .pickerStyle(.segmented)
        .disabled(diabled)
    }
}

#Preview {
    ShelfSectionPicker(diabled: false, section: .constant(.collection))
}
