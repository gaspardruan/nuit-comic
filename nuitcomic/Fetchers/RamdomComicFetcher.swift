//
//  RamdomComicFetcher.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/23.
//

import Foundation
import Observation

@Observable
class RandomComicFetcher {

    var comics: [Comic]
    var firstLoaded = false
    var isLoading = false
    var errorMessage: String? = nil

    init(comics: [Comic]?) {
        if comics == nil {
            self.comics = Array(repeating: Comic(), count: 6)
        } else {
            self.comics = comics!
            firstLoaded = true
        }
    }

    func firstRandom() async {
        guard !firstLoaded else { return }
        await random()
        firstLoaded = true
    }

    @MainActor
    func random() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            comics = try await Self.fetch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    static func fetch() async throws -> [Comic] {
        let decoded: Comics =
            try await ApiClient.shared.request(
                "/getcnxh.html",
                method: .post,
                parameters: [
                    "limit": 6
                ],
                cache: false
            )
        return decoded.data
    }

}
