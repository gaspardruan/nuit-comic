//
//  FetchHelpers.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import SwiftUI

/// Format request parameters as a string.
func formatParamters(from parameters: [String: String]) -> String {
    parameters
        .map {
            "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        .joined(separator: "&")
}
