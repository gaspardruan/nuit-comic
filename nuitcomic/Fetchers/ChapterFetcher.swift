//
//  ChapterFetcher.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

final class ChapterFetcher {
    static func fetch(comicId: Int) async -> [Chapter] {
        do {
            let decoded: ChaptersWrapper =  try await ApiClient.shared.request("/chapter_list/tp/\(comicId)-1-1-1000")
            return decoded.result.list
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
}
