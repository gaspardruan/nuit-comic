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
    private var orderType: OrderType {
        OrderType(rawValue: orderRaw) ?? .time
    }
    private var orderBinding: Binding<OrderType> {
        Binding(
            get: { orderType },
            set: { orderRaw = $0.rawValue }
        )
    }

    @State private var mode: ShelfMode = .browsing
    @State private var section: ShelfSection = .collection

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

    private var isEditing: Bool {
        mode == .editing
    }

    private var allChosen: Bool {
        !currentComics.isEmpty && chosenComicIDs.count == currentComics.count
    }

    private var currentComics: [StoredComic] {
        var comics = section == .collection ? collectedComics : recentComics
        if orderType == .title {
            comics.sort {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }
        return comics
    }

    @State private var chosenComicIDs: Set<Int> = []
    @State private var pendingDeleteIDs: Set<Int> = []
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ShelfContent(
                storedComics: currentComics,
                isEditing: isEditing,
                isGridLayout: isGridLayout,
                selection: $chosenComicIDs
            )
            .navigationTitle("shelf.title")
            .scrollDisabled(currentComics.isEmpty)
            .overlay {
                if currentComics.isEmpty {
                    ContentUnavailableView("shelf.empty", systemImage: "book")
                }
            }
            .alert("shelf.deleteSelected", isPresented: $showDeleteAlert) {
                Button("common.delete", role: .destructive, action: deleteChosenComics)
                Button("common.cancel", role: .cancel) {}
            }
            .toolbarVisibility(isEditing ? .hidden : .visible, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ShelfSettingButton(
                        isEditing: isEditing,
                        chooseDiabled: currentComics.isEmpty,
                        onDoneClick: handleDoneClick,
                        onChooseClick: handleChooseClick,
                        isGridLayout: $isGridLayout,
                        orderType: orderBinding
                    )
                }

                ToolbarItem(placement: .principal) {
                    ShelfSectionPicker(
                        diabled: isEditing,
                        section: $section
                    )
                }

                ToolbarItem(placement: .bottomBar) {
                    ShelfEditButtonGroup(
                        show: isEditing,
                        allChosen: allChosen,
                        deleteDisabled: chosenComicIDs.isEmpty,
                        onDeleteClick: handleDeleteClick,
                        toggleAllChoose: toggleAllChoose
                    )
                }
            }
        }
    }

    private func handleChooseClick() {
        withAnimation {
            mode = .editing
            chosenComicIDs.removeAll()
        }
    }

    private func toggleAllChoose() {
        withAnimation {
            if allChosen {
                chosenComicIDs.removeAll()
            } else {
                chosenComicIDs = Set(currentComics.map(\.id))
            }
        }
    }

    private func handleDoneClick() {
        withAnimation {
            mode = .browsing
            chosenComicIDs.removeAll()
        }
    }

    private func handleDeleteClick() {
        pendingDeleteIDs = chosenComicIDs

        withAnimation {
            mode = .browsing
            showDeleteAlert = true
            chosenComicIDs.removeAll()
        }
    }

    private func deleteChosenComics() {
        withAnimation {
            try? context.transaction {
                for c in currentComics where pendingDeleteIDs.contains(c.id) {
                    context.delete(c)
                }
            }
            pendingDeleteIDs.removeAll()
        }
    }
}

private enum ShelfMode {
    case browsing
    case editing
}

enum ShelfSection {
    case collection
    case recent
}

enum OrderType: CaseIterable, Identifiable, RawRepresentable {
    case time
    case title

    init?(rawValue: String) {
        switch rawValue {
        case "time", "最近阅读":
            self = .time
        case "title", "漫画名":
            self = .title
        default:
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case .time:
            "time"
        case .title:
            "title"
        }
    }

    var localizedTitleKey: LocalizedStringKey {
        switch self {
        case .time:
            "order.time"
        case .title:
            "order.title"
        }
    }

    var id: Self { self }
}

#Preview {
    ShelfView()
        .environment(AppState.defaultState)
        .modelContainer(SampleStoredComic.shared.modelContainer)
}
