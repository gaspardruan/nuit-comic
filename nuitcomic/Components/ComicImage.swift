//
//  Image.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftUI
import Kingfisher

struct ComicImage: View {
    let url: String

    var body: some View {
        KFImage(URL(string: url))
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
            .scaledToFit()
    }
}

#Preview {
    ComicImage(url: "https://icny.tengxun.click/public/bookimages/1497/d4e2b6a1-2426-49e0-a75a-ebd03cfb4f33.jpeg")
}
