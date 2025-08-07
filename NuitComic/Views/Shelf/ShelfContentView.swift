//
//  ShelfContentView.swift
//  NuitComic
//
//  Created by Gaspard Ruan on 2025/8/6.
//

import SwiftUI

struct ShelfContentView: View {
    let storedComics: [StoredComic]
    let isEditing: Bool
    let isGridLayout: Bool
    @Binding var selection: Set<Int>

    private let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    private var modeBinding: Binding<EditMode> {
        Binding(
            get: { isEditing ? .active : .inactive },
            set: { _ in }
        )
    }

    var body: some View {
        if isGridLayout {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(storedComics) { element in
                        NavigationLink(destination: ComicDetailView(comic: element.toComic())) {
                            ShelfGridItemView(active: isEditing, chosen: selection.contains(element.id), comic: element)
                        }
                        .disabled(isEditing)
                        .onTapGesture {
                            if isEditing {
                                withAnimation { toggleSelection(for: element.id) }
                            }
                        }
                    }
                }
                .padding(20)
            }
        } else {
            VStack {
                List(storedComics, id: \.id, selection: $selection) { c in
                    NavigationLink(destination: ComicDetailView(comic: c.toComic())) {
                        ShelfListItemView(comic: c)
                    }
                    .listRowSeparator(c == storedComics.first ? .hidden : .visible, edges: .top)
                    .listRowSeparator(c == storedComics.last ? .hidden : .visible, edges: .bottom)
                    .selectionDisabled(!isEditing)

                }
                .listStyle(.plain)
                .environment(\.editMode, isEditing ? Binding.constant(.active) : Binding.constant(.inactive))
            }
            
        }
    }

    private func toggleSelection(for index: Int) {
        if selection.contains(index) {
            selection.remove(index)
        } else {
            selection.insert(index)
        }
    }
}

#Preview {
    ShelfContentView(
        storedComics: SampleStoredComic.defaultStoredComics, isEditing: false, isGridLayout: true,
        selection: Binding.constant([]))
}

#Preview("List") {
    ShelfContentView(
        storedComics: SampleStoredComic.defaultStoredComics, isEditing: false, isGridLayout: false,
        selection: Binding.constant([]))
}
