//
//  ShelfView.swift
//  NuitComic
//
//  Created by Zhongqiu Ruan on 2025/6/26.
//

import SwiftData
import SwiftUI

struct ShelfView: View {
    // MARK: Setting
    private let gridColumns = Array(
        repeating: GridItem(.flexible()),
        count: 3
    )

    @AppStorage("layout") private var isGridLayout: Bool = true
    @AppStorage("order") private var orderRaw: String = OrderType.time.rawValue
    private var orderBinding: Binding<OrderType> {
        Binding(
            get: { OrderType(rawValue: orderRaw) ?? .time },
            set: { orderRaw = $0.rawValue })
    }

    // MARK: Editing Mode
    @State private var isEditing = false
    @State private var showTabBar = true
    @State private var showBottomBar = false

    // MARK: Data
    @State private var isCollectionSection = true

    @Query(filter: #Predicate<StoredComic> { $0.isCollected == true }, sort: \.storeTime, order: .reverse)
    private var collectedComics: [StoredComic]
    @Query(filter: #Predicate<StoredComic> { $0.isCollected == false }, sort: \.storeTime, order: .reverse)
    private var recentComics: [StoredComic]
    @Environment(\.modelContext) private var context

    var allChosen: Bool {
        chosenComics.count == collectedComics.count
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
            ShelfContentView(
                storedComics: actualComics, isEditing: isEditing, isGridLayout: isGridLayout, selection: $chosenComics
            )
            .navigationTitle("书架")
            .scrollDisabled(collectedComics.isEmpty)
            .overlay(alignment: .top) {
                if actualComics.isEmpty {
                    ContentUnavailableView("书架是空的，快去读漫画吧", systemImage: "book")
                }
            }
            .alert("确定要删除选中的漫画？", isPresented: $showDeleteAlert) {
                Button("删除", role: .destructive, action: deleteChosenComics)
                Button("取消", role: .cancel) {}
            }
            .toolbarVisibility(showBottomBar ? .visible : .hidden, for: .bottomBar)
            .toolbarVisibility(showTabBar ? .visible : .hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    SettingButton(
                        isEditing: isEditing, chooseDiabled: actualComics.isEmpty, onDoneClick: handleDoneClick,
                        onChooseClick: handleChooseClick, isGridLayout: $isGridLayout, orderType: orderBinding)
                }

                ToolbarItem(placement: .principal) {
                    ShelfSectionPicker(isEditing: isEditing, isCollectionSection: $isCollectionSection)
                }

                ToolbarItem(placement: .bottomBar) {
                    EditButtonGroup(
                        allChosen: allChosen, deleteDisabled: chosenComics.isEmpty,
                        onDeleteClick: handleDeleteClick, toggleAllChoose: toggleAllChoose)
                }
            }
        }
    }

    private func handleChooseClick() {
        withAnimation {
            isEditing = true
            chosenComics.removeAll()
        }

        showTabBar = false
        Task { @MainActor in
            try? await Task.sleep(for: .nanoseconds(1))
            withAnimation { showBottomBar = true }
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

struct ComicRouteItem: Hashable {
    let lastReadChapterIndex: Int
    let comic: Comic
}

enum OrderType: String, CaseIterable, Identifiable {
    case time = "最近阅读"
    case title = "漫画名"

    var id: Self { self }
}

#Preview {
    ShelfView()
        .environment(ReadingState())
        .modelContainer(SampleStoredComic.shared.modelContainer)
}
