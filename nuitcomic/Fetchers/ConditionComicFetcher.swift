//
//  SectionComicFetcher.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/24.
//

import Alamofire
import Foundation

@Observable
final class ConditionComicFetcher {
    private let section: HomeSection
    private let pageSize = ServerConfig.pageSize
    private var pageNum = 1

    var comics: [Comic] = []
    var errorMessage: String?
    var firstLoading = false
    var isLoading = false
    var isFinished = false

    init(section: HomeSection) {
        self.section = section
    }

    @MainActor
    func firstLoad() async {
        guard comics.isEmpty else { return }
        firstLoading = true
        defer { firstLoading = false }
        await loadMore()
    }

    @MainActor
    func loadMore() async {
        guard !isLoading, !isFinished else { return }

        var order = ""
        var isOver = false
        switch section {
        case .newComics:
            order = "id desc"
        case .updatedComics:
            order = "update_time desc"
        case .recommendedComics:
            order = ""
        case .mostReadComics:
            order = "view desc"
        case .mostFollowedComics:
            order = "mark desc"
        case .mostReadOverComics:
            order = "view desc"
            isOver = true
        case .mostSearchedComics:
            return
        }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        var fetchedComics: [Comic]
        do {
            fetchedComics = try await fetchComics(order: order, isOver: isOver)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        if fetchedComics.count < pageSize {
            isFinished = true
        }
        comics.append(contentsOf: fetchedComics)
        pageNum += 1
    }

    private func fetchComics(order: String, isOver: Bool) async throws
        -> [Comic]
    {
        let start = (pageNum - 1) * pageSize
        let limit = pageSize

        var fetchedComics: [Comic]

        if !order.isEmpty {
            var paramaters: Parameters = [
                "start": start, "limit": limit, "type": 1,
                "order": order,
            ]

            if isOver { paramaters["mhstatus"] = 1 }

            let decoded: Comics = try await ApiClient.shared.request(
                "/getbook.html",
                method: .post,
                parameters: paramaters
            )

            fetchedComics = decoded.data
        } else {
            let decoded: RecommendComicWrapper = try await ApiClient.shared
                .request("/getpage/tp/1-recommend-\(pageNum)")
            fetchedComics = decoded.result.list
        }

        return fetchedComics
    }

}
