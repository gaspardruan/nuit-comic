//
//  ShelfListView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/8/6.
//

import SwiftUI

struct ShelfListView: View {
    var storedComics: [StoredComic] {
        SampleStoredComic.defaultStoredComics
    }

    @State private var selection = Set<StoredComic>()

    @State private var mode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            List(storedComics, id: \.self, selection: $selection) { c in
                Text(c.title)
            }
            .environment(\.editMode, $mode)
            .toolbar {
                Button("选择") {
                    if mode == .active {
                        mode = .inactive
                    } else {
                        mode = .active
                    }

                }
            }

        }

    }

}

#Preview {

    ShelfListView()

}
