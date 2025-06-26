//
//  RemoteImage.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftUI

struct RemoteImage<Placeholder: View>: View {
    let url: URL
    let placeholder: () -> Placeholder

    @State private var image: Image?
    @State private var hasError = false

    init(
        url: URL,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
            } else if hasError {
                placeholder()
            } else {
                ProgressView()
            }
        }
        .task {
            loadImage()
        }
        
    }

    func loadImage() {
        var request = URLRequest(url: url)
        request.setValue("https://yymh.app/", forHTTPHeaderField: "Referer")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = Image(uiImage: uiImage)
                }
            } else {
                DispatchQueue.main.async {
                    self.hasError = true
                }
            }
        }.resume()
    }
}

#Preview {
    let url =
        "https://icny.tengxun.click/public/bookimages/1497/d4e2b6a1-2426-49e0-a75a-ebd03cfb4f33.jpeg"
    RemoteImage(url: URL(string: url)!) {
        Image("placeholder")
    }
}
