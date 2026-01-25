//
//  ChapterList.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/25.
//

import SwiftUI

struct ChapterList: View {
    let comic: Comic
    let chapters: [Chapter]
    let focusedChapterIndex: Int

    @State private var reversed = false
    @Environment(\.dismiss) private var dismiss

    var actualChapters: [Chapter] {
        reversed ? Array(chapters.reversed()) : chapters
    }

    var focusedChapterID: Int {
        if focusedChapterIndex < chapters.count {
            chapters[focusedChapterIndex].id
        } else {
            0
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(actualChapters.enumerated()), id: \.element.id) {
                    index,
                    chapter in
                    Button {
                        // animation
                        dismiss()
                    } label: {
                        ChapterListItem(
                            title: chapter.title,
                            createTime: chapter.createTime,
                            emphasized: chapter.id == focusedChapterID
                        )
                    }
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppSpacing.loose) {
                        Button {
                            reversed.toggle()
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundStyle(reversed ? .accent : .primary)
                        }

                        Button {
                            withAnimation {
                                proxy.scrollTo(
                                    focusedChapterID,
                                    anchor: .center
                                )
                            }
                        } label: {
                            Image(systemName: "location")

                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(comic.title)
                            .font(.headline)
                        HStack {
                            Text("章节")
                                .foregroundStyle(Color.secondary)

                            Text(
                                "第\(focusedChapterIndex + 1)章，共\(actualChapters.count)章"
                            )
                        }
                        .font(.footnote)

                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func adaptiveIndex(index: Int) -> Int {
        return reversed ? chapters.count - index - 1 : index
    }
}

#Preview {
    NavigationStack {
        ChapterList(
            comic: LocalData.comics[0],
            chapters: LocalData.chapters,
            focusedChapterIndex: 100
        )
    }
}
