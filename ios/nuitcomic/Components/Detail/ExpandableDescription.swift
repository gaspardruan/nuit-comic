//
//  Test.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/25.
//

import SwiftUI

struct ExpandableDescription: View {
    let description: String
    let title: String
    @State private var showFull = false

    var body: some View {
        Text(description)
            .font(.subheadline)
            .foregroundStyle(Color.secondary)
            .lineLimit(3)
            .overlay(alignment: .bottomTrailing) {
                if description.count > 75 {
                    Button("detail.more") { showFull = true }
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color(.systemBackground),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: 60, height: 20)
                            .allowsHitTesting(false)
                        )
                }

            }
            .sheet(isPresented: $showFull) {
                FullDescriptionSheet(text: description, title: title)
            }
    }
}

struct FullDescriptionSheet: View {
    let text: String
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.body)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    ExpandableDescription(
        description:
            "賢秀是業績萬年墊底的健身教練，而組長傑森憑著銷售能力和親密的肢體接觸長年獨佔業績第一名的寶座。當青梅竹馬來到健身房運動時，賢秀要怎麼阻止她遭受到傑森的毒手呢？",
        title: "健身教练"
    )
    .padding()
}
