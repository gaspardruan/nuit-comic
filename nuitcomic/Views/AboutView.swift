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
                        Text("about.intro.title")
                            .font(.title3).bold()
                        Text("about.intro.body")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("about.links") {
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

                Section("about.appData") {
                    HStack {
                        Text("about.comicCount")
                        Spacer()
                        Text(localizedFormat("about.comicCountValue", status?.comicCount ?? 0))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("about.lastSync")
                        Spacer()
                        Text(lastSyncTimeStr)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("about.version")
                        Spacer()
                        Text(version)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("about.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
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
