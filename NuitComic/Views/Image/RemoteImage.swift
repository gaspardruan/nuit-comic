//
//  RemoteImage.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/6/26.
//

import SwiftUI

struct RemoteImagePhase {
    let image: Image?
    let error: Error?

    static let empty = Self(image: nil, error: nil)
    static func success(_ image: Image) -> Self { .init(image: image, error: nil) }
    static func failure(_ error: Error?) -> Self { .init(image: nil, error: error) }
}

@Observable
final class RemoteImageLoader {
    var phase: RemoteImagePhase = .empty
    private var task: Task<Void, Never>?
    private let url: URL
    private let fallback: URL?

    init(url: URL, fallback: URL?) {
        self.url = url
        self.fallback = fallback
        load(url: url, triedFallback: false)
    }

    private func load(url: URL, triedFallback: Bool) {
        task?.cancel()
        task = Task {
            var request = URLRequest(url: url)
            request.setValue("https://yymh.app/", forHTTPHeaderField: "Referer")

            do {
                let (data, _) = try await NetworkManager.shared.imageSession.data(for: request)
                guard !Task.isCancelled else { return }
                if let uiImage = UIImage(data: data) {
                    phase = .success(Image(uiImage: uiImage))
                } else {
                    phase = .failure(nil)
                }
            } catch {
                guard !triedFallback, let fallback else {
                    phase = .failure(error)
                    return
                }
                load(url: fallback, triedFallback: true)
            }
        }
    }

    deinit {
        task?.cancel()
        phase = .empty
    }
}

struct RemoteImage<Content: View>: View {
    @State private var loader: RemoteImageLoader
    private let content: (RemoteImagePhase) -> Content

    init(
        url: URL,
        fallback: URL? = nil,
        @ViewBuilder content: @escaping (RemoteImagePhase) -> Content
    ) {
        _loader = State(initialValue: RemoteImageLoader(url: url, fallback: fallback))
        self.content = content
    }

    var body: some View {
        content(loader.phase)
    }
}

#Preview {
    let url =
        "https://icny.tengxun.click/public/bookimages/1497/d4e2b6a1-2426-49e0-a75a-ebd03cfb4f33.jpeg"
    RemoteImage(url: URL(string: url)!) { phase in
        if let image = phase.image {
            image.resizable()
                .scaledToFit()
        } else if phase.error != nil {
            Color.red
        } else {
            Color.gray
        }
    }
}
