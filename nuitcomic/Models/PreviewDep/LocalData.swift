//
//  LocalData.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

class LocalData {
    static var comics: [Comic] {
        let decoded: Comics = load("comics.json")
        return decoded.data
    }

    static var chapters: [Chapter] {
        let decoded: ChaptersWrapper = load("chapters.json")
        return decoded.result.list
    }
}
