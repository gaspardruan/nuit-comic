//
//  StoredComicBase.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/5.
//

import Foundation
import SwiftData

@Model
class StoredComic : Identifiable, Hashable {
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
    
    var isCollected: Bool

    init(from comic: Comic, lastReadChapterIndex: Int, chapterCount: Int, isCollected: Bool = false, storeTime: Date = .now) {
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
        self.isCollected = isCollected
    }

    func toComic() -> Comic {
        Comic(from: self)
    }
}
