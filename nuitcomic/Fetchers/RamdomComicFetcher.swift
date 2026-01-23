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

    var comics: [Comic] = []
    var isLoading = false
    var errorMessage: String? = nil

    func random() async {
        isLoading = true
        errorMessage = nil

        do {
            let decoded: Comics =
                try await ApiClient.shared.request(
                    "/getcnxh.html",
                    method: .post,
                    parameters: [
                        "limit": 6
                    ],
                    cache: false
                )
            Task { @MainActor in
                comics = decoded.data
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false

    }

}
