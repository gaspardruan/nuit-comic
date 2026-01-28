//
//  ReadingState.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import Foundation

@MainActor
@Observable
final class AppState {
    var showReader: Bool = false

}

struct ReadingComic {
    let c: Comic
    let ch: [Chapter]
}
