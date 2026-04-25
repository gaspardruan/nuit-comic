//
//  ShelfSectionPicker.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/30.
//

import SwiftUI

struct ShelfSectionPicker: View {
    let diabled: Bool
    @Binding var section: ShelfSection

    var body: some View {
        Picker("shelf.sectionPicker", selection: $section) {
            Text("shelf.section.collection").tag(ShelfSection.collection)
            Text("shelf.section.recent").tag(ShelfSection.recent)
        }
        .pickerStyle(.segmented)
        .disabled(diabled)
    }
}

#Preview {
    ShelfSectionPicker(diabled: false, section: .constant(.collection))
}
