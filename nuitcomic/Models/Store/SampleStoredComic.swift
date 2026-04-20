//
//  SampleStoredComic.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/30.
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
            let defaultComics = LocalData.comics[1..<6]
            
            for comic in defaultComics[1..<3] {
                let collectedComic = StoredComic(from: comic,  lastReadChapterIndex: 2, chapterCount: 5, isCollected: true)
                let recentComic = StoredComic(from: comic, lastReadChapterIndex: 3, chapterCount: 5)
                context.insert(collectedComic)
                context.insert(recentComic);
            }
            
            for comic in defaultComics[3..<6] {
                let collectedComic = StoredComic(from: comic,  lastReadChapterIndex: 2, chapterCount: 5, isCollected: true)
                context.insert(collectedComic)
            }
            
            try context.save()
            
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

extension SampleStoredComic {
    static var defaultStoredComics: [StoredComic] {
        LocalData.comics.map { comic in
            StoredComic(from: comic, lastReadChapterIndex: 2, chapterCount: 5)
        }
    }
}
