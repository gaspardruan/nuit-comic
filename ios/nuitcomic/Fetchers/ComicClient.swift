//
//  ComicClient.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/4/22.
//

final class ComicClient {
    static let shared = ComicClient()

    private init() {}

    func fetchAllComics() async throws -> [Comic] {
        let decoded: Comics = try await ApiClient.shared.request(
            "/getbook.html", method: .post, cache: false)
        return decoded.data
    }
}
