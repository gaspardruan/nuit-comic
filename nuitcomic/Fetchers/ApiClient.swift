//
//  APIClient.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/22.
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
        prefetch(urls: urls, onImageLoaded: nil, onFinished: onFinished)
    }

    func prefetch(
        urls: [String],
        onImageLoaded: ((String, CGSize) -> Void)? = nil,
        onFinished: (() -> Void)? = nil
    ) {
        guard !urls.isEmpty else { return }

        let options: KingfisherOptionsInfo = [
            .requestModifier(ServerConfig.requestModifier),
            .cacheOriginalImage,
        ]

        let group = DispatchGroup()

        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }

            group.enter()
            KingfisherManager.shared.retrieveImage(with: url, options: options) {
                result in
                if case let .success(value) = result {
                    DispatchQueue.main.async {
                        onImageLoaded?(urlString, value.image.size)
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            onFinished?()
        }
    }
}
