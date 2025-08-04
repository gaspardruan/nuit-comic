//
//  SampleStoredComic.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/8/4.
//

import Foundation
import SwiftData

@MainActor
class SampleStoredComic {
    static let shared = SampleStoredComic()
    
    let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([CollectedComic.self, RecentComic.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
            let context = modelContainer.mainContext
            let defaultComics = NetworkManager.defaultComics
            
            for comic in defaultComics {
                let collectedComic = CollectedComic(from: comic, lastReadChapterIndex: 2, chapterCount: 5)
                let recentComic = RecentComic(from: comic, lastReadChapterIndex: 3, chapterCount: 5)
                context.insert(collectedComic)
                context.insert(recentComic);
            }
            
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

extension SampleStoredComic {
    static var defaultStoredComics: [StoredComic] {
        NetworkManager.defaultComics.map { comic in
            CollectedComic(from: comic, lastReadChapterIndex: 2, chapterCount: 5)
        }
    }
}
