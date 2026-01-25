//
//  Image.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import Kingfisher
import SwiftUI

struct ComicImage: View {
    let url: String
    let fallbackUrl: String?

    @State private var currentUrl: String
    @State private var didFallback = false

    init(url: String, fallbackUrl: String? = nil) {
        self.url = url
        self.fallbackUrl = fallbackUrl
        _currentUrl = State(initialValue: url)
    }

    var body: some View {
        KFImage(URL(string: currentUrl))
            .requestModifier(ServerConfig.requestModifier)
            .cacheOriginalImage()
            .placeholder {
                Image("placeholder")
                    .resizable()
                    .scaledToFit()
            }
            .retry(maxCount: 2, interval: .seconds(2))
            .fade(duration: 0.2)
            .resizable()
            .onFailure { _ in
                guard !didFallback, let fallbackUrl, fallbackUrl != currentUrl
                else { return }

                didFallback = true
                currentUrl = fallbackUrl
            }
    }
}

#Preview {
    ComicImage(
        url:
            "https://icny.tengxun.click/public/bookimages/1497/d4e2b6a1-2426-49e0-a75a-ebd03cfb4f33.jpeg"
    )
}
