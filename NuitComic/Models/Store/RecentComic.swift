//
//  CollectedComic.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/8/4.
//

import Foundation
import SwiftData

@Model
class RecentComic: StoredComic {
    var id: Int
    var title: String
    var image: String
    var cover: String
    var desc: String
    var author: String
    var keyword: String
    var follow: Int
    var view: Int64
    var updateTime: Date
    var isOver: Bool
    var score: Double

    var lastReadChapterIndex: Int
    var chapterCount: Int
    var storeTime: Date

    init(from comic: Comic, lastReadChapterIndex: Int, chapterCount: Int, storeTime: Date = .now) {
        self.id = comic.id
        self.title = comic.title
        self.image = comic.image
        self.cover = comic.cover
        self.desc = comic.description
        self.author = comic.author
        self.keyword = comic.keyword
        self.follow = comic.follow
        self.view = comic.view
        self.updateTime = comic.updateTime
        self.isOver = comic.isOver
        self.score = comic.score
        self.lastReadChapterIndex = lastReadChapterIndex
        self.chapterCount = chapterCount
        self.storeTime = storeTime
    }
}
