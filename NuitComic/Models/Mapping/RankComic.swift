//
//  RankComic.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/6/30.
//


import Foundation

struct RankComicResponse: Decodable {
    let mostSearchComics: [Comic]
    
    enum CodingKeys: String, CodingKey {
        case mostSearchComics = "most_search"
    }
}

struct RankComicResponseWrapper: Decodable {
    let result: RankComicResponse
}

