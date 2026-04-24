//
//  ShelfEditButtonGroup.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/30.
//

import SwiftUI

struct ShelfEditButtonGroup: View {
    let show: Bool
    let allChosen: Bool
    let deleteDisabled: Bool
    let onDeleteClick: () -> Void
    let toggleAllChoose: () -> Void

    var body: some View {
        if show {
            HStack {
                Button("common.delete", action: onDeleteClick)
                    .disabled(deleteDisabled)
                Spacer()
                Button(allChosen ? "shelf.deselectAll" : "shelf.selectAll", action: toggleAllChoose)
            }
        }
    }
}

#Preview {
    ShelfEditButtonGroup(
        show: true,
        allChosen: false,
        deleteDisabled: false,
        onDeleteClick: {},
        toggleAllChoose: {}
    )
}
