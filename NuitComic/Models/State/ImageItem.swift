//
//  ImageItem.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/7/2.
//

import Foundation

struct ImageItem: Hashable {
    let url: String
    let indexInChapter: Int
    let chapterIndex: Int
    let indexInList: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(chapterIndex * 1000 + indexInChapter)
    }
}
