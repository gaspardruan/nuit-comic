//
//  ChapterListButtonView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import SwiftUI

struct ChapterListButtonView: View {
    let comicID: Int
    let title: String
    let updateTime: Date
    let isOver: Bool

    @State private var showContent = false
    
    @State private var fullscreen = false
    
    @Environment(ReadingState.self) private var reader

    init(comicID: Int, title: String, updateTime: Date, isOver: Bool) {
        self.comicID = comicID
        self.title = title
        self.updateTime = updateTime
        self.isOver = isOver
    }
    
    var chapters: [Chapter] {
        reader.readingComic?.chapters ?? []
    }

    var updateInfo: String {
        let d = Self.formatter.localizedString(for: updateTime, relativeTo: Date())
        return isOver ? "\(chapters.count)章·完本" : "连载至\(chapters.count)章·\(d)"
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
                    title: title, chapters: chapters,
                    focusedChapterIndex: chapters.count / 2, showContent: $showContent)
            }

        }
        .task {
            reader.readingComic = nil
            await reader.read(comicID: comicID, title: title)
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
