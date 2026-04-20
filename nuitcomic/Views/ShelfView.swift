//
//  ShelfView.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/22.
//

import SwiftData
import SwiftUI

struct ShelfView: View {
    @AppStorage("layout") private var isGridLayout: Bool = true
    @AppStorage("order") private var orderRaw: String = OrderType.time.rawValue
    private var orderBinding: Binding<OrderType> {
        Binding(
            get: { OrderType(rawValue: orderRaw) ?? .time },
            set: { orderRaw = $0.rawValue }
        )
    }

    // MARK: Editing Mode
    @State private var isEditing = false
    @State private var showTabBar = true
    @State private var showBottomBar = false

    // MARK: Data
    @State private var isCollectionSection = true

    @Query(
        filter: #Predicate<StoredComic> { $0.isCollected == true },
        sort: \.storeTime,
        order: .reverse
    )
    private var collectedComics: [StoredComic]
    @Query(
        filter: #Predicate<StoredComic> { $0.isCollected == false },
        sort: \.storeTime,
        order: .reverse
    )
    private var recentComics: [StoredComic]
    @Environment(\.modelContext) private var context

    var allChosen: Bool {
        chosenComics.count == actualComics.count
    }

    var actualComics: [StoredComic] {
        var comics: [StoredComic]
        if isCollectionSection {
            comics = collectedComics
        } else {
            comics = recentComics
        }
        if orderBinding.wrappedValue == .title {
            comics.sort {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }
        return comics
    }

    // MARK: Delete Data
    @State private var chosenComics: Set<Int> = []
    @State private var toDeleteComics: [StoredComic] = []
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ShelfContent(
                storedComics: actualComics,
                isEditing: isEditing,
                isGridLayout: isGridLayout,
                selection: $chosenComics
            )
            .navigationTitle("书架")
            .scrollDisabled(actualComics.isEmpty)
            .overlay {
                if actualComics.isEmpty {
                    ContentUnavailableView("书架是空的，快去读漫画吧", systemImage: "book")
                }
            }
            .alert("确定要删除选中的漫画？", isPresented: $showDeleteAlert) {
                Button("删除", role: .destructive, action: deleteChosenComics)
                Button("取消", role: .cancel) {}
            }
            .toolbarVisibility(showTabBar ? .visible : .hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ShelfSettingButton(
                        isEditing: isEditing,
                        chooseDiabled: actualComics.isEmpty,
                        onDoneClick: handleDoneClick,
                        onChooseClick: handleChooseClick,
                        isGridLayout: $isGridLayout,
                        orderType: orderBinding
                    )
                }

                ToolbarItem(placement: .principal) {
                    ShelfSectionPicker(
                        diabled: isEditing,
                        collectionSelected: $isCollectionSection
                    )
                }

                ToolbarItem(placement: .bottomBar) {
                    ShelfEditButtonGroup(
                        show: showBottomBar,
                        allChosen: allChosen,
                        deleteDisabled: chosenComics.isEmpty,
                        onDeleteClick: handleDeleteClick,
                        toggleAllChoose: toggleAllChoose
                    )
                }
            }
        }
    }

    private func handleChooseClick() {
        withAnimation {
            isEditing = true
            chosenComics.removeAll()
            showTabBar = false
        }

        Task { @MainActor in
            showBottomBar = true
        }
    }

    private func toggleAllChoose() {
        withAnimation {
            if allChosen {
                chosenComics.removeAll()
            } else {
                chosenComics.formUnion(actualComics.map { $0.id })
            }
        }
    }

    private func handleDoneClick() {
        withAnimation {
            isEditing = false
            showTabBar = true
            showBottomBar = false
            chosenComics.removeAll()
        }
    }

    private func handleDeleteClick() {
        toDeleteComics = actualComics.filter { comic in
            chosenComics.contains(comic.id)
        }

        withAnimation {
            isEditing = false
            showTabBar = true
            showBottomBar = false

            showDeleteAlert = true
            chosenComics.removeAll()
        }
    }

    private func toggleSelection(for index: Int) {
        if chosenComics.contains(index) {
            chosenComics.remove(index)
        } else {
            chosenComics.insert(index)
        }
    }

    private func deleteChosenComics() {
        withAnimation {
            try? context.transaction {
                for c in toDeleteComics {
                    context.delete(c)
                }
            }
        }
    }
}

enum OrderType: String, CaseIterable, Identifiable {
    case time = "最近阅读"
    case title = "漫画名"

    var id: Self { self }
}

#Preview {
    ShelfView()
        .environment(AppState())
        .modelContainer(SampleStoredComic.shared.modelContainer)
}
