//
//  SearchComic.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/7.
//

import Foundation

struct SearchComic: Decodable {
    let list: [Comic]?
}

struct SearchComicWrapper: Decodable {
    let result: SearchComic
    let code: Int
}
