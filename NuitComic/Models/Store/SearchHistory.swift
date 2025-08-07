//
//  SearchHistory.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/7.
//

import Foundation
import SwiftData

@Model
class SearchHistory {
    var text: String
    var time: Date
    
    init(text: String, time: Date) {
        self.text = text
        self.time = time
    }
}
