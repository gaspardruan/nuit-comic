//
//  ReaderImgaeView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/6.
//

import SwiftUI

struct ReaderImgaeView: View {
    let url: String
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        RemoteImage(url: URL(string: url)!) {
            phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()

            } else if phase.error != nil {
                Color.red
                    .aspectRatio(0.618, contentMode: .fill)
            } else {
                Color.gray
                    .aspectRatio(0.618, contentMode: .fill)
            }
        }
        .frame(width: screenWidth)
    }
}

#Preview {
    ReaderImgaeView(url: NetworkManager.defaultChapters.first!.imageList.first!)
}
