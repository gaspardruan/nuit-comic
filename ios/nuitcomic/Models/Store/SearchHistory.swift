//
//  SearchHistoryStore.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/4/23.
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
