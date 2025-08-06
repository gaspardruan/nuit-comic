//
//  Comic.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import Foundation

struct Comic: Identifiable, Decodable, Equatable, Hashable {
    let id: Int
    let title: String
    let image: String
    let cover: String
    let description: String
    let author: String
    let keyword: String
    let follow: Int
    let view: Int64
    let updateTime: Date
    let isOver: Bool
    let score: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case image
        case cover
        case description = "desc"
        case author = "auther"
        case keyword
        case follow = "mark"
        case view
        case updateTime = "update_time"
        case isOver = "mhstatus"
        case score = "pingfen"
    }
    
    init(from comic: StoredComic) {
        self.id = comic.id
        self.title = comic.title
        self.image = comic.image
        self.cover = comic.cover
        self.description = comic.desc
        self.author = comic.author
        self.keyword = comic.keyword
        self.follow = comic.follow
        self.view = comic.view
        self.updateTime = comic.updateTime
        self.isOver = comic.isOver
        self.score = comic.score
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = Int(try container.decode(String.self, forKey: .id))!
        self.title = try container.decode(String.self, forKey: .title)
        self.image = Server.image.rawValue + (try container.decode(String.self, forKey: .image))
        self.cover = Server.image.rawValue + (try container.decode(String.self, forKey: .cover))
        self.description = try container.decode(String.self, forKey: .description)
        self.author = try container.decode(String.self, forKey: .author)
        self.keyword = try container.decode(String.self, forKey: .keyword)
        self.follow = Int(try container.decode(String.self, forKey: .follow)) ?? 0
        self.view = Int64(try container.decode(String.self, forKey: .view)) ?? 0
        let dateString = try container.decode(String.self, forKey: .updateTime)
        self.updateTime = transTime(from: dateString)
        let isOver = try container.decode(String.self, forKey: .isOver)
        self.isOver = isOver == "1" ? true : false
        self.score = Double(try container.decodeIfPresent(String.self, forKey: .score) ?? "9.0") ?? 9.0
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
