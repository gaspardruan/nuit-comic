//
//  ShelfView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftData
import SwiftUI

struct ShelfView: View {
    @Query private var collectedComics: [CollectedComic]
    @Query private var recentComics: [RecentComic]
    @Environment(\.modelContext) private var context

    @State private var isFavorite = true
    @State private var isEditting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                SimpleGrid(comics: collectedComics, columnNum: 3) { comic, _ in
                    RemoteImage(url: URL(string: comic.image)!) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(5 / 7, contentMode: .fill)
                                .cornerRadius(4)
                        } else if phase.error != nil {
                            Color.red
                                .aspectRatio(5 / 7, contentMode: .fill)
                        } else {
                            Color.gray
                                .aspectRatio(5 / 7, contentMode: .fill)
                        }
                    }
                  
                }
                .padding(20)
            }
            .navigationTitle("书架")
            .toolbarVisibility(isEditting ? .visible : .hidden, for: .bottomBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("选择", systemImage: "checkmark.circle") {
                            withAnimation {
                                isEditting.toggle()
                            }
                        }

                        Section {
                            Button("网格", systemImage: "square.grid.2x2") {
                                print("网格")
                            }

                            Button("列表", systemImage: "list.bullet") {
                                print("列表")
                            }
                        }

                        Section("排序方式...") {
                            Button("最近阅读") {
                                print("1")
                            }
                            Button("书名") {
                                print("2")
                            }
                            Button("手动") {
                                print("3")
                            }
                        }

                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .imageScale(.large)
                    }

                }

                ToolbarItem(placement: .principal) {
                    Picker("选择类型", selection: $isFavorite) {
                        Text("最近收藏").tag(true)
                        Text("最近阅读").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()

                }

                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button("网格", systemImage: "square.grid.2x2") {
                            print("网格")
                        }

                        Spacer()

                        Button("网格", systemImage: "square.grid.2x2") {
                            print("网格")
                        }

                        Spacer()

                        Button("网格", systemImage: "square.grid.2x2") {
                            print("网格")
                        }
                    }

                }

            }

        }

    }
}

#Preview {
    ShelfView()
        .modelContainer(SampleStoredComic.shared.modelContainer)
}
