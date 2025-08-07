//
//  NetworkManager.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/29.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    /// Set for `Server.api`
    private let cacheDuration: TimeInterval = 300

    /// Set for `Server.image`
    let imageSession: URLSession

    init() {
        let memoryCapacity = 50 * 1024 * 1024
        let diskCapacity = 200 * 1024 * 1024
        let diskPath = "imageCache"

        let customCache = URLCache(
            memoryCapacity: memoryCapacity, diskCapacity: diskCapacity,
            directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent(diskPath))

        let config = URLSessionConfiguration.default
        config.urlCache = customCache
        config.requestCachePolicy = .useProtocolCachePolicy

        imageSession = URLSession(configuration: config)
    }

    func data(from request: URLRequest, noCache: Bool = false) async throws -> Data {

        if !noCache, let cachedData = Cache.shared.get(for: request) {
            printRequest(request, label: "cache")
            return cachedData
        }

        printRequest(request, label: "request")
        let (data, _) = try await URLSession.shared.data(for: request)
        if !noCache {
            Cache.shared.set(data, for: request)
        }
        return data
    }

    func post(relativeURL: String, start: Int, limit: Int, order: String, isOver: Bool? = nil) async throws -> Data {
        let url = URL(string: "\(Server.api.rawValue)\(relativeURL)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var parameters: [(String, String)] = [
            ("order", order),
            ("type", "1"),
            ("start", String(start)),
            ("limit", String(limit)),
        ]
        if let over = isOver {
            parameters.append(("mhstatus", over ? "1" : "0"))
        }
        request.httpBody = formatParamters(from: parameters).data(using: .utf8)

        return try await data(from: request)
    }

    func post(relativeURL: String, limit: Int) async throws -> Data {
        let url = URL(string: "\(Server.api.rawValue)\(relativeURL)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let parameters: [(String, String)] = [
            ("type", "1"),
            ("limit", String(limit)),
        ]
        request.httpBody = formatParamters(from: parameters).data(using: .utf8)

        return try await data(from: request, noCache: true)
    }

    func get(relativeURL: String) async throws -> Data {
        let url = URL(string: "\(Server.api.rawValue)\(relativeURL)")!
        let request = URLRequest(url: url)
        return try await data(from: request)
    }

    func prefetchImages(imageURLs: [String]) async {
        await withTaskGroup { group in
            for url in imageURLs {
                var request = URLRequest(url: URL(string: url)!)
                request.setValue("https://yymh.app/", forHTTPHeaderField: "Referer")
                group.addTask {
                    try? await self.imageSession.data(for: request)
                }
            }
        }
    }

}

extension NetworkManager {
    static var defaultComics: [Comic] {
        let decoded: Comics = load("defaultComics.json")
        return decoded.data
    }
}

extension NetworkManager {
    static var defaultChapters: [Chapter] {
        let decoded: ChaptersWrapper = load("defaultChapters.json")
        return decoded.result.list
    }
}
