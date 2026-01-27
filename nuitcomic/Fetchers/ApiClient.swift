//
//  APIClient.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import Alamofire
import Foundation
import Kingfisher

final class ApiClient {
    static let shared = ApiClient()

    let session: Session

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15

        self.session = Session(configuration: configuration)
    }

    func request<T: Decodable>(
        _ relativeUrl: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding? = nil,
        cache: Bool = true
    ) async throws -> T {
        let cacheKey =
            "\(relativeUrl)_\(method.rawValue)_\(parameters?.description ?? "")"
        let absoluteUrl = "\(ServerConfig.apiBaseUrl)\(relativeUrl)"

        if cache, let cached = try? jsonStorage.object(forKey: cacheKey) {
            return try JSONDecoder().decode(T.self, from: cached)
        }

        let encoding =
            encoding
            ?? {
                switch method {
                case .get:
                    return URLEncoding.default
                case .post:
                    return URLEncoding.httpBody
                default:
                    return JSONEncoding.default
                }
            }()

        let request = session.request(
            absoluteUrl,
            method: method,
            parameters: parameters,
            encoding: encoding,
        )
        .validate()

        let data = try await request.serializingData().value

        if cache {
            try? jsonStorage.setObject(data, forKey: cacheKey)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func prefetch(urls: [String], onFinished: (() -> Void)? = nil) {
        guard !urls.isEmpty else { return }

        let wrappedUrls = urls.compactMap { URL(string: $0) }
        let prefetcher = ImagePrefetcher(
            urls: wrappedUrls,
            options: [
                .requestModifier(ServerConfig.requestModifier),
                .cacheOriginalImage,
            ],
            completionHandler: { _, _, _ in
                onFinished?()
            }
        )
        prefetcher.maxConcurrentDownloads = 9
        prefetcher.start()
    }
}
