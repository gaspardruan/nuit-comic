//
//  NetworkManager.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/29.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    private let cacheDuration: TimeInterval = 300

    func data(from request: URLRequest, noCache: Bool = false) async throws -> Data {
        let trickeyRequest = request.trickyRequest()

        if !noCache, let cachedResponse = URLCache.shared.cachedResponse(for: trickeyRequest) {
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
        if !noCache {
            URLCache.shared.storeCachedResponse(cachedResponse.withTimestamp(), for: trickeyRequest)
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

}

extension CachedURLResponse {
    var timestamp: Date {
        if let userInfo = userInfo, let date = userInfo["timestamp"] as? Date {
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
        guard self.httpMethod == "POST" else { return self }

        var urlString = self.url!.absoluteString
        if let body = self.httpBody {
            urlString += "?\(String(data: body, encoding: .utf8) ?? "")"
        }
        return URLRequest(url: URL(string: urlString)!)
    }
}


extension NetworkManager {
    static var defaultComics: [Comic] {
        let decoded: Comics = load("defaultComics.json")
        return decoded.data
    }
}
