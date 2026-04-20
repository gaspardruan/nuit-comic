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
            Button("完成", action: onDoneClick)
        } else {
            Menu {
                Button(
                    "选择",
                    systemImage: "checkmark.circle",
                    action: onChooseClick
                )
                .disabled(chooseDiabled)

                Section("布局") {
                    Picker("Layout", selection: $isGridLayout) {
                        Label("网格", systemImage: "square.grid.2x2").tag(true)
                        Label("列表", systemImage: "list.bullet").tag(false)
                    }
                }

                Section("排序方式...") {
                    Picker("Order", selection: $orderType) {
                        ForEach(OrderType.allCases) { type in
                            Text(type.rawValue).tag(type)
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
