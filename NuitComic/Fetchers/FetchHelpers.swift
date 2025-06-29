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
