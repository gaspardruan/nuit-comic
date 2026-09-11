//
//  RankComic.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/23.
//

struct RankComicResponse: Decodable {
    let mostSearchComics: [Comic]

    enum CodingKeys: String, CodingKey {
        case mostSearchComics = "most_search"
    }
}

struct RankComicResponseWrapper: Decodable {
    let result: RankComicResponse
}
