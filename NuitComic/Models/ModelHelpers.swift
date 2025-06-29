//
//  ModelHelpers.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import Foundation

/// Load file from the file system.
///
/// `load` expects a JSON file. Use the method to load the recipe data; for
/// example: `DataStore(recipes: load("recipeData.json"))`.
func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
