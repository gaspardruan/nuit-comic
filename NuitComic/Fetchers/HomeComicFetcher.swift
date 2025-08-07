//
//  HomeComicFetcher.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/6/26.
//

import Foundation

@Observable
class HomeComicFetcher {
    var homeComic: HomeComic?

    func fetchAll() async throws {
        async let newAndRecommend = getNewAndRecommend()
        async let updated = getUpdatedComics()
        async let mostRead = getMostReadComics()
        async let mostFollowed = getMostFollowedComics()
        async let mostReadOver = getMostReadOverComics()
        async let mostSearched = getMostSearchedComics()

        let (
            (newComics, recommendedComics), updatedComics, mostReadComics, mostFollowedComics, mostReadOverComics,
            mostSearchedComics
        ) = try await (
            newAndRecommend, updated, mostRead, mostFollowed, mostReadOver, mostSearched
        )

        Task { @MainActor in
            homeComic = HomeComic(
                newComics: newComics,
                updatedComics: updatedComics,
                recommendedComics: recommendedComics,
                mostReadComics: mostReadComics,
                mostFollowedComics: mostFollowedComics,
                mostReadOverComics: mostReadOverComics,
                mostSearchedComics: mostSearchedComics
            )
        }
    }

    private func getNewAndRecommend() async throws -> (
        newComics: [Comic], recommendedComics: [Comic]
    ) {
        let data = try await NetworkManager.shared.get(relativeURL: "/yymhindex.html")
        let decoded = try JSONDecoder().decode(
            HomeComicResponseWrapper.self,
            from: data
        )

        var newComics: [Comic] = []
        newComics.append(contentsOf: decoded.data.newComics1.data)
        newComics.append(contentsOf: decoded.data.newComics2.data)

        var recommendedComics: [Comic] = []
        recommendedComics.append(contentsOf: decoded.data.recommendedComics1.data)
        recommendedComics.append(contentsOf: decoded.data.recommendedComics2.data)

        return (newComics, recommendedComics)
    }

    private func getUpdatedComics() async throws -> [Comic] {
        let data = try await NetworkManager.shared.post(
            relativeURL: "/getbook.html", start: 0, limit: 6, order: "update_time desc")
        let decoded = try JSONDecoder().decode(Comics.self, from: data)
        return decoded.data
    }

    private func getMostReadComics() async throws -> [Comic] {
        let data = try await NetworkManager.shared.post(
            relativeURL: "/getbook.html", start: 0, limit: 6, order: "view desc")
        let decoded = try JSONDecoder().decode(Comics.self, from: data)
        return decoded.data
    }

    private func getMostReadOverComics() async throws -> [Comic] {
        let data = try await NetworkManager.shared.post(
            relativeURL: "/getbook.html", start: 0, limit: 6, order: "view desc", isOver: true)
        let decoded = try JSONDecoder().decode(Comics.self, from: data)
        return decoded.data
    }

    private func getMostFollowedComics() async throws -> [Comic] {
        let data = try await NetworkManager.shared.post(
            relativeURL: "/getbook.html", start: 0, limit: 6, order: "mark desc")
        let decoded = try JSONDecoder().decode(Comics.self, from: data)
        return decoded.data
    }

    private func getMostSearchedComics() async throws -> [Comic] {
        let data = try await NetworkManager.shared.get(relativeURL: "/rank/type/1")
        let decoded = try JSONDecoder().decode(
            RankComicResponseWrapper.self,
            from: data
        )
        return Array(decoded.result.mostSearchComics.prefix(9))
    }

}
