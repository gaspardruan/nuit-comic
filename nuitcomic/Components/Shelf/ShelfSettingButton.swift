//
//  SheflSettingButton.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/30.
//

import SwiftUI

struct ShelfSettingButton: View {
    let isEditing: Bool
    let chooseDiabled: Bool
    let onDoneClick: () -> Void
    let onChooseClick: () -> Void

    @Binding var isGridLayout: Bool
    @Binding var orderType: OrderType

    var body: some View {
        if isEditing {
            Button("common.done", action: onDoneClick)
        } else {
            Menu {
                Button(
                    "common.select",
                    systemImage: "checkmark.circle",
                    action: onChooseClick
                )
                .disabled(chooseDiabled)

                Section("shelf.layout") {
                    Picker("shelf.layout", selection: $isGridLayout) {
                        Label("shelf.layout.grid", systemImage: "square.grid.2x2").tag(true)
                        Label("shelf.layout.list", systemImage: "list.bullet").tag(false)
                    }
                }

                Section("shelf.order") {
                    Picker("shelf.order", selection: $orderType) {
                        ForEach(OrderType.allCases) { type in
                            Text(type.localizedTitleKey).tag(type)
                        }
                    }
                }

            } label: {
                Image(systemName: "ellipsis")
                    .imageScale(.large)
            }

        }
    }
}

#Preview {
    ShelfSettingButton(
        isEditing: false,
        chooseDiabled: false,
        onDoneClick: {},
        onChooseClick: {},
        isGridLayout: Binding.constant(true),
        orderType: Binding.constant(.time)
    )
}

#Preview("Editing") {
    ShelfSettingButton(
        isEditing: true,
        chooseDiabled: false,
        onDoneClick: {},
        onChooseClick: {},
        isGridLayout: Binding.constant(true),
        orderType: Binding.constant(.time)
    )
}
