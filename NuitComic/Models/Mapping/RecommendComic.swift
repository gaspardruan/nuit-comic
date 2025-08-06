//
//  RecommendComic.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/30.
//

import Foundation

struct RecommendComic: Decodable {
    let list: [Comic]
}

struct RecommendComicWrapper: Decodable {
    let result: RecommendComic
}
