//
//  SectionComicFetcher.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/27.
//

import SwiftUI

@Observable
class SectionComicFetcher {
    private let section: HomeSection
    private static let pageSize = 20
    private var pageNum = 1

    var comics: [Comic] = []
    var isFinished: Bool = false
    var isLoading: Bool = false

    init(section: HomeSection) {
        self.section = section
    }

    func loadNextPage() async {
        isLoading = true
        
        let url = URL(string: Server.api.rawValue + "/getbook.html")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        var parameters: [(String, String)]
        switch section {
        case .newComics:
            parameters = [
                ("order", "id desc"),
                ("type", "1"),
                ("start", "\((pageNum - 1) * SectionComicFetcher.pageSize)"),
                ("limit", "\(SectionComicFetcher.pageSize)")
            ]
        default:
            parameters = [
                ("order", "id desc"),
                ("type", "1"),
                ("start", "\((pageNum - 1) * SectionComicFetcher.pageSize)"),
                ("limit", "\(SectionComicFetcher.pageSize)"),
            ]
        }
        request.httpBody = formatParamters(from: parameters).data(using: .utf8)
        
        var decoded: Comics
        do {
            let data = try await NetworkManager.shared.data(from: request)
//            let (data, _) = try await URLSession.shared.data(for: request)
            decoded = try JSONDecoder().decode(Comics.self, from: data)
        } catch {
            print(error.localizedDescription)
            return
        }
        
        
        Task {@MainActor in
            if (decoded.data.count < SectionComicFetcher.pageSize) {
                isFinished = true
            }
            comics.append(contentsOf: decoded.data)
            pageNum += 1
            isLoading = false
        }
        
    }
}
