//
//  Chapter.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import Foundation

struct Chapter: Decodable, Identifiable {
    let id: Int
    let title: String
    let createTime: Date
    let imageList: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createTime = "create_time"
        case imageList = "imagelist"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = Int(try container.decode(String.self, forKey: .id))!
        self.title = try container.decode(String.self, forKey: .title)
        let dateString = try container.decode(String.self, forKey: .createTime)
        self.createTime = transTime(from: dateString)
        let imageListString = try container.decode(String.self, forKey: .imageList)
        self.imageList = imageListString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }.map { "\(Server.image.rawValue)\($0)" }
    }
}

struct Chapters: Decodable {
    let list: [Chapter]
}

struct ChaptersWrapper: Decodable {
    let result: Chapters
}
