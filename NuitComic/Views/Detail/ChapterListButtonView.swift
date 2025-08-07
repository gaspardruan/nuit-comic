//
//  ChapterListButtonView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/7/2.
//

import SwiftUI

struct ChapterListButtonView: View {
    let comic: Comic
    let lastReadChapterIndex: Int

    @State private var showContent = false

    @State private var fullscreen = false

    @Environment(ReadingState.self) private var reader

    var chapters: [Chapter] {
        reader.readingComic?.chapters ?? []
    }

    var updateInfo: String {
        let d = Self.formatter.localizedString(for: comic.updateTime, relativeTo: Date())
        return comic.isOver ? "\(chapters.count)章·完本" : "连载至\(chapters.count)章·\(d)"
    }

    var body: some View {
        Button {
            showContent = true
        } label: {
            HStack {
                Text("目录")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                HStack {
                    if chapters.count > 0 {
                        Text(updateInfo)
                            .font(.subheadline)
                            .transition(.opacity)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 130, height: 20)

                    }

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)

        }
        .sheet(isPresented: $showContent) {
            NavigationStack {
                ChapterListView(
                    comic: comic, chapters: chapters,
                    focusedChapterIndex: lastReadChapterIndex, showContent: $showContent)
            }

        }

    }

    private static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.unitsStyle = .full
        return f
    }()
}

#Preview {
    ChapterListButtonView(comic: NetworkManager.defaultComics[0], lastReadChapterIndex: 3)
        .environment(ReadingState())
        .padding(.horizontal, 20)
}
