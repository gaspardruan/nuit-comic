//
//  ImageItem.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import Foundation

struct ImageItem: Hashable {
    let url: String
    let indexInChapter: Int
    let chapterIndex: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(chapterIndex * 1000 + indexInChapter)
    }
}
