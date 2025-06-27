//
//  RemoteImage.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
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
    
    @State private var phase = RemoteImagePhase.empty

    init(
        url: URL,
        @ViewBuilder content: @escaping (RemoteImagePhase) -> Content
    ) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
        .task {
            await loadImage()
        }
    }

    func loadImage() async {
        var request = URLRequest(url: url)
        request.setValue("https://yymh.app/", forHTTPHeaderField: "Referer")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let uiImage = UIImage(data: data) {
                let image = Image(uiImage: uiImage)
                                phase = .success(image)
            } else {
                phase = .failure(nil)
            }
        } catch {
            phase = .failure(error)
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
