//
//  Untitled.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftUI

struct ShelfView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Shelf View")
            Text("已经到底了!")
//                .font(.callout)
        }
        .padding()
    }
}

#Preview {
    ShelfView()
}
