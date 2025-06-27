//
//  HomeComicFetcher.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftUI

@Observable
class HomeComicFetcher {
    var homeComic: HomeComic?

    func fetchAll() async throws {
        async let newAndRecommend = getNewAndRecommend()

        let (newComics, recommendedComics) = try await newAndRecommend

        Task { @MainActor in
            homeComic = HomeComic(
                newComics: newComics,
                updatedComics: [],
                recommendedComics: recommendedComics,
                mostReadComics: [],
                mostFollowedComics: [],
                mostReadOverComics: [],
                mostSearchedComics: []
            )
        }
    }
    
    static var defaultComics: [Comic] {
        let decoded: HomeComicResponseWrapper = load("homecomic.json")

        var newComics: [Comic] = []
        newComics.append(contentsOf: decoded.data.newComics1.data)
        newComics.append(contentsOf: decoded.data.newComics2.data)
        return newComics
    }

    private func getNewAndRecommend() async throws -> (
        newComics: [Comic], recommendedComics: [Comic]
    ) {
//        let url = URL(string: Server.api.rawValue + "/yymhindex.html")!
//        let request = URLRequest(url: url)
//        let (data, _) = try await URLSession.shared.data(for: request)
//        let decoded = try JSONDecoder().decode(
//            HomeComicResponseWrapper.self,
//            from: data
//        )
        let decoded: HomeComicResponseWrapper = load("homecomic.json")

        var newComics: [Comic] = []
        newComics.append(contentsOf: decoded.data.newComics1.data)
        newComics.append(contentsOf: decoded.data.newComics2.data)

        var recommendedComics: [Comic] = []
        recommendedComics.append(contentsOf: decoded.data.recommendedComics1.data)
        recommendedComics.append(contentsOf: decoded.data.recommendedComics2.data)

        return (newComics, recommendedComics)
    }
}
