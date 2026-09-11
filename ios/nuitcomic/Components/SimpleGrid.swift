//
//  SimpleGrid.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/22.
//

import SwiftUI

struct SimpleGrid<T: Identifiable, Content: View>: View {
    let comics: [T]
    let columnNum: Int
    //    var space: CGFloat = 12
    let gridItem: (T, Int) -> Content

    var rowNum: Int {
        comics.count / columnNum
    }

    var restNum: Int {
        comics.count % columnNum
    }

    var rowIndices: Range<Int> {
        guard !comics.isEmpty else { return 0..<0 }
        let rowCount = (comics.count + columnNum - 1) / columnNum
        return 0..<rowCount
    }

    var body: some View {
        Grid {
            ForEach(rowIndices, id: \.self) { rowIndex in
                let rowCount = rowNum == rowIndex ? restNum : columnNum
                GridRow {
                    let rowComics = Array(
                        comics[
                            rowIndex * columnNum..<rowIndex * columnNum
                                + rowCount
                        ].enumerated()
                    )
                    ForEach(rowComics, id: \.element.id) { index, comic in
                        let globalIndex = rowIndex * columnNum + index
                        gridItem(comic, globalIndex)
                    }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        SimpleGrid(comics: Array(LocalData.comics.prefix(6)), columnNum: 3) {
            comic,
            _ in
            ComicImage(url: comic.image)
        }
        .padding(20)
    }
}
