//
//  HomeComic.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/22.
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

enum HomeSection {
    case newComics
    case updatedComics
    case recommendedComics
    case mostReadComics
    case mostFollowedComics
    case mostReadOverComics
    case mostSearchedComics

    var localizedTitleKey: LocalizedStringKey {
        switch self {
        case .newComics:
            "home.section.new"
        case .updatedComics:
            "home.section.updated"
        case .recommendedComics:
            "home.section.recommended"
        case .mostReadComics:
            "home.section.mostRead"
        case .mostFollowedComics:
            "home.section.mostFollowed"
        case .mostReadOverComics:
            "home.section.mostReadOver"
        case .mostSearchedComics:
            "home.section.mostSearched"
        }
    }
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
