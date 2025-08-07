//
//  RecommendComic.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/6/30.
//

import Foundation

struct RecommendComic: Decodable {
    let list: [Comic]
}

struct RecommendComicWrapper: Decodable {
    let result: RecommendComic
}
