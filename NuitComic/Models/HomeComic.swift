//
//  HomeComic.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftUI

struct HomeComic {
    let newComics: [Comic]
    let updatedComics: [Comic]
    let recommendedComics: [Comic]
    let mostReadComics: [Comic]
    let mostFollowedComics: [Comic]
    let mostReadOverComics: [Comic]
    let mostSearchedComics: [Comic]
}

enum HomeSection: String {
    case newComics = "新作"
    case updatedComics = "更新"
    case recommendedComics = "推荐"
    case mostReadComics = "最多阅读"
    case mostFollowedComics = "最多收藏"
    case mostReadOverComics = "最多阅读（完结）"
    case mostSearchedComics = "最多搜索"
}

struct Comics: Decodable {
    let data: [Comic]
}

struct HomeComicResponse: Decodable {
    let newComics1: Comics
    let newComics2: Comics
    let recommendedComics1: Comics
    let recommendedComics2: Comics

    enum CodingKeys: String, CodingKey {
        case newComics1 = "jphc1"
        case newComics2 = "jphc2"
        case recommendedComics1 = "rmtj1"
        case recommendedComics2 = "rmtj2"
    }
}

struct HomeComicResponseWrapper: Decodable {
    let data: HomeComicResponse
}
