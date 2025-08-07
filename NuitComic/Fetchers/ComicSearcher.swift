//
//  ComicSearcher.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/7.
//

import Foundation

@Observable
class ComicSearcher {
    var text = ""
    var comics: [Comic] = []
    var isLoading = true
    var submitted = false

    private let pageSize = 15
    private var pageNum = 2
    var isFinished = false

    private var currentTask: Task<Void, Never>? = nil

    func search() {
        if text.isEmpty {
            comics = []
            return
        }

        currentTask?.cancel()

        currentTask = Task {
            try? await Task.sleep(for: .seconds(1))
            await doSearch()
        }
    }

    private func doSearch() async {
        if text.isEmpty {
            comics = []
            return
        }

        var searchComics: [Comic]
        var status: Bool
        isLoading = true
        do {
            let data = try await NetworkManager.shared.get(relativeURL: "/searchk?keyword=\(text)&type=1&pageNo=1")
            let decoded = try JSONDecoder().decode(SearchComicWrapper.self, from: data)
            if decoded.code == 0 {
                searchComics = []
            } else {
                searchComics = decoded.result.list!
            }
            status = false
        } catch {
            if (error as? URLError)?.code != .cancelled {
                print("请求失败：", error.localizedDescription)
            }
            searchComics = []
            status = true
        }

        Task { @MainActor in
            comics = searchComics
            isLoading = status
        }
    }

    func resetPage() {
        isFinished = false
        pageNum = 2
        submitted = false
    }

    func handleComicAppearIn(currentIndex: Int) async {
        guard submitted && !isFinished else { return }
        if currentIndex < comics.count - 5 { return }

        var pageComics: [Comic]
        do {
            let data = try await NetworkManager.shared.get(relativeURL: "/searchk?keyword=\(text)&type=1&pageNo=\(pageNum)")
            let decoded = try JSONDecoder().decode(SearchComicWrapper.self, from: data)
            if decoded.code == 0 {
                pageComics = []
            } else {
                pageComics = decoded.result.list!
            }
        } catch {
            print(error.localizedDescription)
            return
        }

        Task { @MainActor in
            if pageComics.count < pageSize {
                isFinished = true
            }
            comics.append(contentsOf: pageComics)
            pageNum += 1
        }

    }
}
