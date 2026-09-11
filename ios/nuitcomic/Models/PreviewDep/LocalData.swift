//
//  LocalData.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/22.
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
    
    static var chapters2: [Chapter] {
        let decoded: ChaptersWrapper = load("chapters2.json")
        return decoded.result.list
    }
}
