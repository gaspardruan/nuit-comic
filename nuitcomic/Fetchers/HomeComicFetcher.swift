//
//  HomeComicFetcher.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/23.
//

import Foundation
import Observation

@Observable
class HomeComicFetcher {

    var homeComic: HomeComic?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func fetchAll() async {
        isLoading = true
        errorMessage = nil

        async let newAndRecommend = getNewAndRecommend()
        async let updated = getUpdatedComics()
        async let mostRead = getMostReadComics()
        async let mostFollowed = getMostFollowedComics()
        async let mostReadOver = getMostReadOverComics()
        async let mostSearched = getMostSearchedComics()

        do {
            let (
                (newComics, recommendedComics),
                updatedComics,
                mostReadComics,
                mostFollowedComics,
                mostReadOverComics,
                mostSearchedComics
            ) = try await (
                newAndRecommend,
                updated,
                mostRead,
                mostFollowed,
                mostReadOver,
                mostSearched
            )

            homeComic = HomeComic(
                newComics: newComics,
                updatedComics: updatedComics,
                recommendedComics: recommendedComics,
                mostReadComics: mostReadComics,
                mostFollowedComics: mostFollowedComics,
                mostReadOverComics: mostReadOverComics,
                mostSearchedComics: mostSearchedComics
            )

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Private API

    private func getNewAndRecommend() async throws -> (
        newComics: [Comic], recommendedComics: [Comic]
    ) {

        let decoded: HomeComicResponseWrapper =
            try await ApiClient.shared.request(
                "/yymhindex.html"
            )

        var newComics: [Comic] = []
        newComics.append(contentsOf: decoded.data.newComics1.data)
        newComics.append(contentsOf: decoded.data.newComics2.data)

        var recommendedComics: [Comic] = []
        recommendedComics.append(
            contentsOf: decoded.data.recommendedComics1.data
        )
        recommendedComics.append(
            contentsOf: decoded.data.recommendedComics2.data
        )

        return (newComics, recommendedComics)
    }

    private func getUpdatedComics() async throws -> [Comic] {

        let decoded: Comics =
            try await ApiClient.shared.request(
                "/getbook.html",
                method: .post,
                parameters: [
                    "start": 0,
                    "limit": 6,
                    "type": 1,
                    "order": "update_time desc",
                ]
            )

        return decoded.data
    }

    private func getMostReadComics() async throws -> [Comic] {

        let decoded: Comics =
            try await ApiClient.shared.request(
                "/getbook.html",
                method: .post,
                parameters: [
                    "start": 0,
                    "limit": 6,
                    "type": 1,
                    "order": "view desc",
                ]
            )

        return decoded.data
    }

    private func getMostReadOverComics() async throws -> [Comic] {

        let decoded: Comics =
            try await ApiClient.shared.request(
                "/getbook.html",
                method: .post,
                parameters: [
                    "start": 0,
                    "limit": 6,
                    "type": 1,
                    "order": "view desc",
                    "mhstatus": 1,
                ]
            )

        return decoded.data
    }

    private func getMostFollowedComics() async throws -> [Comic] {

        let decoded: Comics =
            try await ApiClient.shared.request(
                "/getbook.html",
                method: .post,
                parameters: [
                    "start": 0,
                    "limit": 6,
                    "type": 1,
                    "order": "mark desc",
                ]
            )

        return decoded.data
    }

    private func getMostSearchedComics() async throws -> [Comic] {

        let decoded: RankComicResponseWrapper =
            try await ApiClient.shared.request(
                "/rank/type/1"
            )

        return Array(decoded.result.mostSearchComics.prefix(9))
    }
}
