//
//  RandomSectionView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/30.
//

import SwiftUI

struct RandomSectionView: View {
    @State private var comics: [Comic] = []
    @State private var isLoading = true
    private let count = 6
    private let title = "猜你喜欢"

    var body: some View {
        SectionView(comics: comics) {
            Button(action: handleTap) {
                HStack {
                    Text(title)
                        .font(.title3)
                        .foregroundColor(.primary)
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .foregroundColor(.secondary)
                }
                .fontWeight(.semibold)
            }
        }.task {
            if isLoading {
                await random()
            }
        }
    }

    private func handleTap() {
        Task {
            await random()
        }
    }

    private func random() async {
        isLoading = true
        do {
            let data = try await NetworkManager.shared.post(relativeURL: "/getcnxh.html", limit: count)
            let decoded = try JSONDecoder().decode(Comics.self, from: data)
            Task { @MainActor in
                comics = decoded.data
                isLoading = false
            }
        } catch {
            print(error.localizedDescription)
        }

    }
}

#Preview {
    ScrollView {
        RandomSectionView()
    }

}
