//
//  BigCoverView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import SwiftUI

struct BigCoverView: View {
    let url: String
    let fallback: String
    let height: CGFloat
    
    var body: some View {
        RemoteImage(
            url: URL(string: url)!,
            fallback: URL(string: fallback)
        ) {
            phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(6)

            } else if phase.error != nil {
                Color.red
                    .aspectRatio(15 / 8, contentMode: .fit)
            } else {
                Color.gray
                    .aspectRatio(15 / 8, contentMode: .fit)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    var coverHeight: CGFloat {
        (UIScreen.main.bounds.width - 2 * 20) * 8 / 15
    }
    let comic = NetworkManager.defaultComics.first!
    BigCoverView(url: comic.cover, fallback: comic.image, height: coverHeight)
}
