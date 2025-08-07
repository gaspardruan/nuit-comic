//
//  Cache.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/3.
//

import Foundation

final class Cache {
    static let shared = Cache()

    private let cache: NSCache<WrappedRequest, CacheEntry> = {
        let cache = NSCache<WrappedRequest, CacheEntry>()
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()

    private let cacheDuration: TimeInterval = 300

    func set(_ data: Data, for request: URLRequest) {
        let key = WrappedRequest(request)
        let entry = CacheEntry(data: data, expireAt: Date().addingTimeInterval(cacheDuration))
        cache.setObject(entry, forKey: key, cost: data.count)

        Task.detached { [weak self] in
            try? await Task.sleep(for: .seconds(self?.cacheDuration ?? 300))
            self?.removeExpired(for: key)
        }
    }

    func get(for request: URLRequest) -> Data? {
        let key = WrappedRequest(request)
        guard let entry = cache.object(forKey: key), !entry.isExpired else {
            cache.removeObject(forKey: key)
            return nil
        }
        return entry.data
    }

    private func removeExpired(for key: WrappedRequest) {
        if let entry = cache.object(forKey: key), entry.isExpired {
            cache.removeObject(forKey: key)
        }
    }

    func clear() {
        cache.removeAllObjects()
    }
}

final class WrappedRequest: NSObject {
    private let request: URLRequest

    init(_ request: URLRequest) {
        self.request = request
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WrappedRequest else { return false }
        return request == other.request
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(request.url)
        hasher.combine(request.httpMethod)
        hasher.combine(request.httpBody)
        return hasher.finalize()
    }
}

final class CacheEntry {
    let data: Data
    let expireAt: Date

    init(data: Data, expireAt: Date) {
        self.data = data
        self.expireAt = expireAt
    }

    var isExpired: Bool {
        return Date() > expireAt
    }
}
