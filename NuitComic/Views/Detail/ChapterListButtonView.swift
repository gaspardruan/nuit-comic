//
//  ChapterListButtonView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import SwiftUI

struct ChapterListButtonView: View {
    let title: String
    let updateTime: Date
    let isOver: Bool

    @State private var showContent = false
    @State private var chapterFetcher: ChapterFectcher
    
    @State private var fullscreen = false

    init(comicID: Int, title: String, updateTime: Date, isOver: Bool) {
        self.title = title
        self.updateTime = updateTime
        self.isOver = isOver
        self.chapterFetcher = ChapterFectcher(comicID: comicID)
    }
    
    var chapterCount: Int {
        chapterFetcher.chapters.count
    }

    var updateInfo: String {
        let d = Self.formatter.localizedString(for: updateTime, relativeTo: Date())
        return isOver ? "\(chapterCount)章·完本" : "连载至\(chapterCount)章·\(d)"
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
                    if chapterCount > 0 {
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
                    title: title, chapters: chapterFetcher.chapters,
                    focusedChapterIndex: chapterFetcher.chapters.count / 2)
            }

        }
        .fullScreenCover(isPresented: $fullscreen, content: {
            Text("Read comic")
        })
        .task {
            await chapterFetcher.fetch()
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
    let now = Date()
    let offsetComponents = DateComponents(year: -2, month: -9, day: -3)
    let date = Calendar.current.date(byAdding: offsetComponents, to: now)!
    ChapterListButtonView(comicID: 361, title: "秘密教学", updateTime: date, isOver: false)
        .padding(.horizontal, 20)
}
