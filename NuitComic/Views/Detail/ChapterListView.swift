//
//  ChapterListView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import SwiftData
import SwiftUI

struct ChapterListView: View {
    let comic: Comic
    let chapters: [Chapter]
    let focusedChapterIndex: Int

    @Binding var showContent: Bool

    @State private var reversed = false

    @Environment(\.dismiss) private var dismiss
    @Environment(ReadingState.self) private var reader
    @Environment(\.modelContext) private var context

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
                ForEach(Array(actualChapters.enumerated()), id: \.element.id) { index, chapter in
                    Button {
                        withAnimation {
                            showContent = false
                            reader.startReadingFrom(chapterIndex: adaptiveIndex(index: index))
                            reader.syncStoredComics(context: context, chapterIndex: index)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(chapter.title)
                                    .font(.subheadline)
                                    .fontWeight(chapter.id == focusedChapterID ? .bold : .semibold)
                                    .foregroundStyle(chapter.id == focusedChapterID ? .accent : .primary)

                                Text(chapter.createTime.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits)))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button {
                            reversed.toggle()
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .symbolRenderingMode(reversed ? .monochrome : .hierarchical)
                        }

                        Button {
                            withAnimation {
                                proxy.scrollTo(focusedChapterID, anchor: .center)
                            }
                        } label: {
                            Image(systemName: "location.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(comic.title)
                            .font(.headline)
                        HStack {
                            Text("章节")
                                .foregroundColor(.secondary)

                            Text("第\(focusedChapterIndex + 1)章，共\(actualChapters.count)章")
                        }
                        .font(.footnote)

                    }
                }
            }
        }
        .navigationTitle(comic.title)
        .navigationBarTitleDisplayMode(.inline)

    }

    func adaptiveIndex(index: Int) -> Int {
        return reversed ? chapters.count - index - 1 : index
    }
}

#Preview {
    NavigationStack {
        ChapterListView(
            comic: NetworkManager.defaultComics[2], chapters: NetworkManager.defaultChapters, focusedChapterIndex: 100,
            showContent: .constant(true))
    }
    .environment(ReadingState())
    .modelContainer(SampleStoredComic.shared.modelContainer)
}
