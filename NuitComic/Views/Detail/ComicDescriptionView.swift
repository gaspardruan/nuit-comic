//
//  ComicIntroductionView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/7/2.
//

import SwiftUI
import ExpandableText

struct ComicDescriptionView: View {
    let description: String
    
    var body: some View {
        ExpandableText(description)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(4)
            .moreButtonText("更多")
            .moreButtonColor(.cyan)
    }
}

#Preview {
    ComicDescriptionView(description: "这是漫画的介绍")
}
