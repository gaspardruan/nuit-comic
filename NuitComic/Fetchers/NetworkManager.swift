//
//  NetworkManager.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/29.
//

import SwiftUI

class NetworkManager {
    static let shared = NetworkManager()

    private let cacheDuration: TimeInterval = 300

    func data(from request: URLRequest) async throws -> Data {
        let trickeyRequest = request.trickyRequest()
        if let cachedResponse = URLCache.shared.cachedResponse(for: trickeyRequest) {
            let age = Date().timeIntervalSince(cachedResponse.timestamp)
            if age < cacheDuration {
                printRequest(request, label: "cache")
                return cachedResponse.data
            } else {
                URLCache.shared.removeCachedResponse(for: trickeyRequest)
            }
        }

        printRequest(request, label: "request")
        let (data, response) = try await URLSession.shared.data(for: request)
        let cachedResponse = CachedURLResponse(response: response, data: data)
        URLCache.shared.storeCachedResponse(
            cachedResponse.withTimestamp(),
            for: trickeyRequest
        )

        return data
    }

}

extension CachedURLResponse {
    var timestamp: Date {
        if let userInfo = userInfo,
            let date = userInfo["timestamp"] as? Date
        {
            return date
        }
        return Date.distantPast
    }

    func withTimestamp(_ date: Date = Date()) -> CachedURLResponse {
        CachedURLResponse(
            response: self.response,
            data: self.data,
            userInfo: ["timestamp": date],
            storagePolicy: self.storagePolicy
        )
    }
}

extension URLRequest {
    func trickyRequest() -> URLRequest {
        guard self.httpMethod == "POST" else {return self}
        
        var urlString = self.url!.absoluteString
        if let body = self.httpBody {
            urlString += "?\(String(data: body, encoding: .utf8) ?? "")"
        }
        return URLRequest(url: URL(string: urlString)!)
    }
}
