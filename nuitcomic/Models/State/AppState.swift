//
//  ReadingState.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/1/26.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    private enum UpdateStorageKey {
        static let lastCheckAt = "appUpdate.lastCheckAt"
        static let dismissedVersion = "appUpdate.dismissedVersion"
        static let cachedManifest = "appUpdate.cachedManifest"
    }

    private static let updateManifestURL = URL(
        string:
            "https://gist.githubusercontent.com/gaspardruan/2ad73c9fce007aa19ccbfc06a04b1a9b/raw/nuitcomic.json"
    )!
    private static let updatePageURL = URL(
        string: "https://github.com/gaspardruan/nuit-comic/releases")!

    private let storedComicStore: StoredComicStore
    private let comicSearchStore: ComicSearchStore
    private let defaults: UserDefaults
    var readingContext: ReadingContext?
    var availableUpdate: AppUpdateInfo?
    var showUpdateAlert = false

    init(
        storedComicStore: StoredComicStore,
        comicSearchStore: ComicSearchStore = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.storedComicStore = storedComicStore
        self.comicSearchStore = comicSearchStore
        self.defaults = defaults
        self.availableUpdate = Self.loadCachedUpdate(from: defaults)

        if let availableUpdate, !isVersion(availableUpdate.version, newerThan: appVersion()) {
            self.availableUpdate = nil
            Self.clearCachedUpdate(in: defaults)
        }
    }

    func read(
        comic: Comic,
        chapters: [Chapter],
        startChapterIndex: Int,
        transition: ReaderTransition? = nil
    ) {
        storedComicStore.upsert(
            comic: comic,
            lastReadChapterIndex: startChapterIndex,
            chapterCount: chapters.count
        )

        readingContext = .init(
            comic: comic,
            chapters: chapters,
            startChapterIndex: startChapterIndex,
            transition: transition,
            onClose: { index in
                self.close()

                self.storedComicStore.upsert(
                    comic: comic,
                    lastReadChapterIndex: index,
                    chapterCount: chapters.count
                )
            }
        )
    }

    func collectComic(comic: Comic, chapters: [Chapter], lastReadChapterIndex: Int) {
        storedComicStore.insert(
            StoredComic(
                from: comic, lastReadChapterIndex: lastReadChapterIndex,
                chapterCount: chapters.count,
                isCollected: true
            ))
    }

    func unCollectComic(_ comic: StoredComic) {
        storedComicStore.delete(comic)
    }

    func close() {
        withAnimation(.easeOut(duration: 0.22)) {
            readingContext = nil
        }
    }

    func searchIndexStatus() async throws -> SearchStatus {
        return try await comicSearchStore.status()
    }

    func refreshSearchIndexIfNeeded() async throws -> SearchStatus {
        let status = try await comicSearchStore.status()

        if status.comicCount > 0, let lastSyncAt = status.lastSyncAt,
            Date().timeIntervalSince(lastSyncAt) < 12 * 60 * 60
        {
            return status
        }

        return try await refreshSearchIndex()
    }

    func refreshSearchIndex() async throws -> SearchStatus {
        let comics = try await ComicClient.shared.fetchAllComics()
        return try await comicSearchStore.replaceIndex(with: comics)
    }

    func searchComics(query: String, limit: Int? = nil) async throws -> [Comic] {
        try await comicSearchStore.search(query: query, limit: limit)
    }

    var updateInstallURL: URL {
        Self.updatePageURL
    }

    func checkAppUpdateIfNeeded() async {
        guard shouldCheckAppUpdate else { return }
        await checkAppUpdate()
    }

    func dismissUpdateAlert() {
        showUpdateAlert = false

        guard let version = availableUpdate?.version else { return }
        defaults.set(version, forKey: UpdateStorageKey.dismissedVersion)
    }

    private func checkAppUpdate() async {
        defaults.set(Date().timeIntervalSince1970, forKey: UpdateStorageKey.lastCheckAt)

        do {
            let (data, _) = try await URLSession.shared.data(from: Self.updateManifestURL)
            let update = try JSONDecoder().decode(AppUpdateInfo.self, from: data)
            handleUpdateManifest(update)
        } catch {
            print(error.localizedDescription)
            return
        }
    }

    private var shouldCheckAppUpdate: Bool {
        let lastCheckAt = defaults.double(forKey: UpdateStorageKey.lastCheckAt)
        guard lastCheckAt > 0 else { return true }

        return Date().timeIntervalSince1970 - lastCheckAt >= 24 * 60 * 60
    }

    private func handleUpdateManifest(_ update: AppUpdateInfo) {
        guard isVersion(update.version, newerThan: appVersion()) else {
            availableUpdate = nil
            showUpdateAlert = false
            defaults.removeObject(forKey: UpdateStorageKey.dismissedVersion)
            Self.clearCachedUpdate(in: defaults)
            return
        }

        availableUpdate = update
        Self.saveCachedUpdate(update, in: defaults)

        if defaults.string(forKey: UpdateStorageKey.dismissedVersion) != update.version {
            showUpdateAlert = true
        }
    }

    private static func loadCachedUpdate(from defaults: UserDefaults) -> AppUpdateInfo? {
        guard let data = defaults.data(forKey: UpdateStorageKey.cachedManifest) else { return nil }
        return try? JSONDecoder().decode(AppUpdateInfo.self, from: data)
    }

    private static func saveCachedUpdate(_ update: AppUpdateInfo, in defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(update) else { return }
        defaults.set(data, forKey: UpdateStorageKey.cachedManifest)
    }

    private static func clearCachedUpdate(in defaults: UserDefaults) {
        defaults.removeObject(forKey: UpdateStorageKey.cachedManifest)
    }
}

struct AppUpdateInfo: Codable, Equatable {
    let version: String
    let message: String

    var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ReadingContext: Identifiable {
    let id = UUID()
    let comic: Comic
    let chapters: [Chapter]
    let startChapterIndex: Int
    let transition: ReaderTransition?
    let onClose: (Int) -> Void
}

struct ReaderTransition {
    let sourceID: String
    let namespace: Namespace.ID
}
