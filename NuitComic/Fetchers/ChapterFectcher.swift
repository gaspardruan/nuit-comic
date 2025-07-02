//
//  ChapterFectcher.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/3.
//

import Foundation

@Observable
class ChapterFectcher {
    private let comicID: Int

    var chapters: [Chapter] = []

    init(comicID: Int) {
        self.comicID = comicID
    }

    func fetch() async {
        do {
            let data = try await NetworkManager.shared.get(relativeURL: "/chapter_list/tp/\(comicID)-1-1-1000")
            let decoded = try JSONDecoder().decode(ChaptersWrapper.self, from: data)
            chapters = decoded.result.list
        } catch {
            print(error.localizedDescription)
        }
    }

}
