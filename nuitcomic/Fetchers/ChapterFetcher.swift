//
//  ChapterFetcher.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import Foundation

@Observable
final class ChapterFetcher {
    var chapters: [Chapter] = []
    var isLoading: Bool = true
    var errorMessage: String?

    func fetch(comicId: Int) async {
        guard chapters.count == 0 else { return }
        
        errorMessage = nil
        do {
            let decoded: ChaptersWrapper = try await ApiClient.shared.request(
                "/chapter_list/tp/\(comicId)-1-1-1000"
            )
            chapters = decoded.result.list
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
