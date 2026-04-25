//
//  ShelfContent.swift
//  nuitcomic
//
//  Created by Gaspard Ruan on 2026/1/30.
//

import SwiftUI

struct ShelfContent: View {
    let storedComics: [StoredComic]
    let isEditing: Bool
    let isGridLayout: Bool
    @Binding var selection: Set<Int>

    private let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: AppSpacing.compact),
        count: 3
    )

    var body: some View {
        if isGridLayout {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: AppSpacing.standard) {
                    ForEach(storedComics) { element in
                        NavigationLink(
                            destination: ComicDetailView(
                                comic: element.toComic()
                            )
                        ) {
                            ShelfGridItem(
                                active: isEditing,
                                chosen: selection.contains(element.id),
                                comic: element
                            )
                        }
                        .disabled(isEditing)
                        .onTapGesture {
                            if isEditing {
                                withAnimation {
                                    toggleSelection(for: element.id)
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.standard)
            }
        } else {
            VStack {
                List(storedComics, id: \.id, selection: $selection) { c in
                    NavigationLink(
                        destination: ComicDetailView(comic: c.toComic())
                    ) { ShelfListItem(comic: c) }
                    .selectionDisabled(!isEditing)

                }
                .listStyle(.plain)
                .environment(
                    \.editMode,
                    isEditing
                        ? Binding.constant(.active)
                        : Binding.constant(.inactive)
                )
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
    ShelfContent(
        storedComics: SampleStoredComic.defaultStoredComics,
        isEditing: false,
        isGridLayout: true,
        selection: Binding.constant([])
    )
}

#Preview("List") {
    ShelfContent(
        storedComics: SampleStoredComic.defaultStoredComics,
        isEditing: false,
        isGridLayout: false,
        selection: Binding.constant([])
    )
}
