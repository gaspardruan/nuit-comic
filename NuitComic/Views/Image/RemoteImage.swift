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

    static let empty = RemoteImagePhase(image: nil, error: nil)
    static func success(_ image: Image) -> RemoteImagePhase {
        RemoteImagePhase(image: image, error: nil)
    }
    static func failure(_ error: Error?) -> RemoteImagePhase {
        RemoteImagePhase(image: nil, error: error)
    }
}

struct RemoteImage<Content: View>: View {
    let url: URL
    let content: (RemoteImagePhase) -> Content
    let fallback: URL?

    @State private var triedFallback: Bool = false
    @State private var phase = RemoteImagePhase.empty

    init(
        url: URL,
        fallback: URL? = nil,
        @ViewBuilder content: @escaping (RemoteImagePhase) -> Content
    ) {
        self.url = url
        self.content = content
        self.fallback = fallback
    }

    var body: some View {
        content(phase)
            .task {
                await loadImage(url)
            }
    }

    func loadImage(_ url: URL) async {
        var request = URLRequest(url: url)
        request.setValue("https://yymh.app/", forHTTPHeaderField: "Referer")

        do {
            let (data, _) = try await NetworkManager.shared.imageSession.data(for: request)
            if let uiImage = UIImage(data: data) {
                let image = Image(uiImage: uiImage)
                phase = .success(image)
            } else {
                phase = .failure(nil)
            }
        } catch {
            guard triedFallback == false else {
                phase = .failure(error)
                return
            }
            if  let fallback = self.fallback {
                triedFallback = true
                await loadImage(fallback)
            } else {
                phase = .failure(error)
            }
        }
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
