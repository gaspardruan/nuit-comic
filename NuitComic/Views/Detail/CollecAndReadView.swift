//
//  CollecAndReadView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import SwiftUI

struct CollecAndReadView: View {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 20) {
        self.spacing = spacing
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            Button {
                print("123")
            } label: {
                Label("收藏", systemImage: "star")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

            Button {
                print("123")
            } label: {
                Label("开始阅读", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    CollecAndReadView(spacing: 20)
}
