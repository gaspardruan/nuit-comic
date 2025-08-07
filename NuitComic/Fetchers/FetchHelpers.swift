//
//  FetchHelpers.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import Foundation

/// Format request parameters as a string.
func formatParamters(from parameters: [(String, String)]) -> String {
    parameters
        .map {
            "\($0.0)=\($0.1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        .joined(separator: "&")
}

func printRequest(_ request: URLRequest, label: String) {
    if let body = request.httpBody {
        print("\(label): \(request) - \(String(data: body, encoding: .utf8) ?? "")")
    } else {
        print("\(label): \(request) - <Empty> ")
    }
}

func responseWithCache(from original: URLResponse, maxAge: Int = 300) -> HTTPURLResponse {
    guard let httpResponse = original as? HTTPURLResponse else {
        return original as! HTTPURLResponse
    }

    // 复制原始 headers
    var headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, pair in
        if let key = pair.key as? String, let value = pair.value as? String {
            result[key] = value
        }
    }

    // 移除禁止缓存的 header
    headers.removeValue(forKey: "Cache-Control")
    headers.removeValue(forKey: "Pragma")
    headers.removeValue(forKey: "Expires")

    // 添加允许缓存的 header
    headers["Cache-Control"] = "public, max-age=\(maxAge)"

    // 设置 Expires
    let expirationDate = Date().addingTimeInterval(TimeInterval(maxAge))
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "GMT")
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
    headers["Expires"] = formatter.string(from: expirationDate)

    return HTTPURLResponse(
        url: httpResponse.url!,
        statusCode: httpResponse.statusCode,
        httpVersion: "HTTP/1.1",
        headerFields: headers
    ) ?? httpResponse
}
