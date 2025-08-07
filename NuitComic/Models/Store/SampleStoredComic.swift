//
//  SampleStoredComic.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/4.
//

import Foundation
import SwiftData

@MainActor
class SampleStoredComic {
    static let shared = SampleStoredComic()
    
    let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([StoredComic.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
            let context = modelContainer.mainContext
            let defaultComics = NetworkManager.defaultComics[1..<6]
            
            for comic in defaultComics {
                let collectedComic = StoredComic(from: comic,  lastReadChapterIndex: 2, chapterCount: 5, isCollected: true)
                let recentComic = StoredComic(from: comic, lastReadChapterIndex: 3, chapterCount: 5)
                context.insert(collectedComic)
                context.insert(recentComic);
            }
            try context.save()
            
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

extension SampleStoredComic {
    static var defaultStoredComics: [StoredComic] {
        NetworkManager.defaultComics.map { comic in
            StoredComic(from: comic, lastReadChapterIndex: 2, chapterCount: 5)
        }
    }
}
