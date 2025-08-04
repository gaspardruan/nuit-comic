//
//  StoredComicBase.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/8/5.
//

import Foundation
import SwiftData

protocol StoredComic {
    var id: Int { get }
    var title: String { get set }
    var image: String { get set }
    var cover: String { get set }
    var desc: String { get set }
    var author: String { get set }
    var keyword: String { get set }
    var follow: Int { get set }
    var view: Int64 { get set }
    var updateTime: Date { get set }
    var isOver: Bool { get set }
    var score: Double { get set }

    var lastReadChapterIndex: Int { get set }
    var chapterCount: Int { get set }
    var storeTime: Date { get set }
}
