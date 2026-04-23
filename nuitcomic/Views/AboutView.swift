//
//  AboutView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/4/23.
//

import SwiftUI

struct AboutView: View {
    private static let githubURL = URL(string: "https://github.com/gaspardruan/nuit-comic")!
    private static let bilibiliURL = URL(string: "https://space.bilibili.com/470093851")!

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var status: SearchStatus? = nil

    var lastSyncTimeStr: String {
        if let t = status?.lastSyncAt {
            return formatTime(from: t)
        }
        return "-"
    }
    
    var version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""


    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading) {
                        Text("简介")
                            .font(.title3).bold()
                        Text("一个为了学习做的APP，没有什么其他的。")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("相关链接") {
                    Link(destination: Self.githubURL) {
                        Label {
                            Text("Github")
                        } icon: {
                            Image("Github")
                                .resizable()
                                .scaledToFit()
                        }
                        .foregroundStyle(Color.primary)
                    }

                    Link(destination: Self.bilibiliURL) {
                        Label {
                            Text("Bilibili")
                        } icon: {
                            Image("Bilibili")
                                .resizable()
                                .scaledToFit()
                        }
                        .foregroundStyle(Color.primary)
                    }
                }

                Section("APP数据") {
                    HStack {
                        Text("漫画数量")
                        Spacer()
                        Text("\(String(status?.comicCount ?? 0)) 部")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("搜索同步时间")
                        Spacer()
                        Text(lastSyncTimeStr)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("版本号")
                        Spacer()
                        Text(version)
                            .foregroundStyle(.secondary)
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
            .task {
                status = try? await appState.searchIndexStatus()
            }
        }
    }
}

#Preview {
    AboutView()
        .environment(AppState.defaultState)
}
