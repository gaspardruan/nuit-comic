//
//  ChapterList.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/25.
//

import SwiftUI

struct ChapterList: View {
    let comic: Comic
    let chapters: [Chapter]
    let focusedChapterIndex: Int
    let onClick: (Int) -> Void

    @State private var reversed = false
    @Environment(\.dismiss) private var dismiss

    var actualChapters: [Chapter] {
        reversed ? Array(chapters.reversed()) : chapters
    }

    var focusedChapterID: Int {
        focusedChapterIndex < chapters.count ? chapters[focusedChapterIndex].id : 0
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(actualChapters.enumerated()), id: \.element.id) {
                    index,
                    chapter in
                    Button {
                        dismiss()
                        onClick(adaptiveIndex(index: index))
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
                    Button("Close", systemImage: "xmark") {
                        dismiss()
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
                                proxy.scrollTo(focusedChapterID, anchor: .center)
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
                            Text("detail.chapterList.title")
                                .foregroundStyle(Color.secondary)

                            Text(
                                localizedFormat(
                                    "detail.chapterList.focus",
                                    focusedChapterIndex + 1,
                                    actualChapters.count
                                )
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
            focusedChapterIndex: 100,
            onClick: { index in
                print("click \(index)")
            }
        )
    }
}
