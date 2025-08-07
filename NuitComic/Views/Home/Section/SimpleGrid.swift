//
//  SimpleGrid.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/4.
//

import SwiftUI

struct SimpleGrid<T: Identifiable, Content: View>: View {
    let comics: [T]
    let columnNum: Int
    var space: CGFloat = 12
    let gridItem: (T, Int) -> Content

    var rowNum: Int {
        comics.count / columnNum
    }
    
    var restNum: Int {
        comics.count % columnNum
    }


    var body: some View {
        Grid(horizontalSpacing: space, verticalSpacing: space) {
            ForEach(0...rowNum, id: \.self) { rowIndex in
                let rowCount = rowNum == rowIndex ? restNum : columnNum
                GridRow {
                    let rowComics = Array(comics[rowIndex * columnNum..<rowIndex * columnNum + rowCount].enumerated())
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
        SimpleGrid(comics: Array(NetworkManager.defaultComics.prefix(5)), columnNum: 3) { comic, index in
            SectionItemView(comic: comic)
        }
        .padding(20)
    }
}
