//
//  EditButtonGroup.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/8/6.
//

import SwiftUI

struct EditButtonGroup: View {
    let allChosen: Bool
    let deleteDisabled: Bool
    let onDeleteClick: () -> Void
    let toggleAllChoose: () -> Void
    
    var body: some View {
        HStack {
            Button("删除", action: onDeleteClick)
                .disabled(deleteDisabled)
            Spacer()
            Button(allChosen ? "取消全选" : "全选", action: toggleAllChoose)
        }
    }
}

#Preview {
    EditButtonGroup(allChosen: false, deleteDisabled: false, onDeleteClick: {}, toggleAllChoose: {})
}
