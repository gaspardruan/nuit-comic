//
//  SectionComicFetcher.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/6/27.
//

import Foundation

@Observable
class SectionComicFetcher {
    private let section: HomeSection
    private let pageSize = 20
    private var pageNum = 1

    var comics: [Comic] = []
    var isFinished: Bool = false
    var isLoading: Bool = false

    init(section: HomeSection) {
        self.section = section
    }

    func loadNextPage() async {
        var order: String?
        var isOver: Bool? = nil
        switch section {
        case .newComics:
            order = "id desc"
        case .updatedComics:
            order = "update_time desc"
        case .mostReadComics:
            order = "view desc"
        case .mostFollowedComics:
            order = "mark desc"
        case .mostReadOverComics:
            order = "view desc"
            isOver = true
        case .recommendedComics:
            // Recommended comics are requested by method Get.
            order = nil
        case .mostSearchedComics:
            // MostSearched comics are
            return
        }
        let start = (pageNum - 1) * pageSize
        let limit = pageSize

        isLoading = true
        var moreComics: [Comic]
        do {
            if let order = order {
                let data = try await NetworkManager.shared.post(
                    relativeURL: "/getbook.html", start: start, limit: limit, order: order, isOver: isOver)
                let decoded = try JSONDecoder().decode(Comics.self, from: data)
                moreComics = decoded.data
            } else {
                let data = try await NetworkManager.shared.get(relativeURL: "/getpage/tp/1-recommend-\(pageNum)")
                let decoded = try JSONDecoder().decode(RecommendComicWrapper.self, from: data)
                moreComics = decoded.result.list
            }
        } catch {
            print(error.localizedDescription)
            return
        }

        Task { @MainActor in
            if moreComics.count < pageSize {
                isFinished = true
            }
            comics.append(contentsOf: moreComics)
            pageNum += 1
            isLoading = false
        }

    }
}
