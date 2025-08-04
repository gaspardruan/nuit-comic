//
//  SearchView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftUI

struct SearchView: View {
    @State private var isFavorite = true

    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(0..<100) { index in
                    VStack {

                        Text("Item    \(index)")

                    }.frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("搜索")

        }

    }
}

#Preview {
    SearchView()
}
