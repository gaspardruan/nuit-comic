//
//  AboutView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/11.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let githubURL = URL(string: "https://github.com/gaspardruan/nuit-comic")!
    private let bilibiliURL = URL(string: "https://space.bilibili.com/470093851")!

    var body: some View {

        List {
            Section("相关链接") {
                Link(destination: githubURL) {
                    Label {
                        Text("Github")
                            .foregroundStyle(Color.primary)
                    } icon: {
                        Image("Github")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                    }
                }

                Link(destination: bilibiliURL) {
                    Label {
                        Text("Bilibili")
                            .foregroundStyle(Color.primary)
                    } icon: {
                        Image("Bilibili")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                    }
                }
            }

        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
            }
        }

    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
