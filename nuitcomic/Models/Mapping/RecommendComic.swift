//
//  RecommendComic.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/24.
//

import Foundation

struct RecommendComic: Decodable {
    let list: [Comic]
}

struct RecommendComicWrapper: Decodable {
    let result: RecommendComic
}
