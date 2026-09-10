import Foundation
import Observation
import SwiftData

enum ServerConfig {
    static let imageBaseUrl = "https://example.invalid"
}

final class ApiClient {
    static let shared = ApiClient()
    func prefetch(urls: [String], onImageLoaded: ((String, CGSize) -> Void)?) {}
}

// Control network completion while exercising the real AppState and SQLite store.
@MainActor
final class ComicClient {
    static let shared = ComicClient()
    private(set) var requestCount = 0
    private var pending: CheckedContinuation<[Comic], Error>?
    private var waiter: CheckedContinuation<Void, Never>?

    func fetchAllComics() async throws -> [Comic] {
        requestCount += 1
        return try await withCheckedThrowingContinuation {
            pending = $0
            waiter?.resume()
            waiter = nil
        }
    }

    func waitForRequest() async {
        if pending == nil {
            await withCheckedContinuation { waiter = $0 }
        }
    }

    func finish(_ result: Result<[Comic], Error>) {
        let request = pending!
        pending = nil
        request.resume(with: result)
    }
}

@main
@MainActor
struct SearchIndexRegressionTests {
    static func main() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("search-index-tests-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }

        try await firstSyncNotifiesSearch(directory: directory)
        try await failedSyncCanRetry(directory: directory)
        try await cachedIndexSurvivesFailure(directory: directory)
        try await emptyCatalogFinishesLoading(directory: directory)
    }

    static func firstSyncNotifiesSearch(directory: URL) async throws {
        let app = try makeApp(databaseURL: directory.appendingPathComponent("first.sqlite"))
        let before = try await app.searchComics(query: "Adventure")
        precondition(before.isEmpty && !app.hasSearchIndex)

        let refresh = Task { await app.refreshSearchIndexIfNeeded() }
        await ComicClient.shared.waitForRequest()
        precondition(app.isRefreshingSearchIndex && !app.hasSearchIndex)

        let requestCount = ComicClient.shared.requestCount
        await app.refreshSearchIndexIfNeeded()
        precondition(ComicClient.shared.requestCount == requestCount)

        // SearchView observes this timestamp as part of its task identity.
        let (updates, continuation) = AsyncStream<Void>.makeStream()
        withObservationTracking {
            _ = app.searchStatus?.lastSyncAt
        } onChange: {
            continuation.yield(())
            continuation.finish()
        }

        ComicClient.shared.finish(.success([sampleComic]))
        await refresh.value
        for await _ in updates { break }

        let after = try await app.searchComics(query: "Adventure")
        precondition(after.map(\.id) == [sampleComic.id])
        precondition(app.hasSearchIndex && !app.isRefreshingSearchIndex)
        precondition(app.searchIndexError == nil)
        print("PASS: first sync notifies observers and makes the unchanged query searchable")
        print("PASS: overlapping startup refreshes share one network request")

        await app.refreshSearchIndexIfNeeded()
        precondition(ComicClient.shared.requestCount == requestCount)
        print("PASS: a fresh local index does not require another download")
    }

    static func failedSyncCanRetry(directory: URL) async throws {
        let app = try makeApp(databaseURL: directory.appendingPathComponent("retry.sqlite"))
        let first = Task { await app.refreshSearchIndexIfNeeded() }
        await ComicClient.shared.waitForRequest()
        ComicClient.shared.finish(.failure(URLError(.notConnectedToInternet)))
        await first.value
        precondition(!app.hasSearchIndex && app.searchIndexError != nil)
        precondition(!app.isRefreshingSearchIndex)

        let retry = Task { await app.refreshSearchIndexIfNeeded(force: true) }
        await ComicClient.shared.waitForRequest()
        precondition(app.isRefreshingSearchIndex && app.searchIndexError == nil)
        ComicClient.shared.finish(.success([sampleComic]))
        await retry.value
        let results = try await app.searchComics(query: "Adventure")
        precondition(app.hasSearchIndex && results.count == 1)
        print("PASS: a failed first sync exposes an error and retry restores search")
    }

    static func cachedIndexSurvivesFailure(directory: URL) async throws {
        let store = ComicSearchStore(databaseURL: directory.appendingPathComponent("cached.sqlite"))
        let savedStatus = try await store.replaceIndex(with: [sampleComic])
        let app = try makeApp(store: store)

        let refresh = Task { await app.refreshSearchIndexIfNeeded(force: true) }
        await ComicClient.shared.waitForRequest()
        let during = try await app.searchComics(query: "Adventure")
        precondition(app.hasSearchIndex && during.count == 1)
        ComicClient.shared.finish(.failure(URLError(.timedOut)))
        await refresh.value

        let after = try await app.searchComics(query: "Adventure")
        precondition(app.hasSearchIndex && after.count == 1 && app.searchIndexError != nil)
        precondition(app.searchStatus?.lastSyncAt == savedStatus.lastSyncAt)
        print("PASS: a failed background update preserves searchable local data")
    }

    static func emptyCatalogFinishesLoading(directory: URL) async throws {
        let app = try makeApp(databaseURL: directory.appendingPathComponent("empty.sqlite"))
        let refresh = Task { await app.refreshSearchIndexIfNeeded() }
        await ComicClient.shared.waitForRequest()
        ComicClient.shared.finish(.success([]))
        await refresh.value
        precondition(app.hasSearchIndex && !app.isRefreshingSearchIndex)
        precondition(app.searchStatus?.comicCount == 0 && app.searchIndexError == nil)
        print("PASS: a successfully downloaded empty catalog does not remain in loading state")
    }

    static func makeApp(databaseURL: URL) throws -> AppState {
        try makeApp(store: ComicSearchStore(databaseURL: databaseURL))
    }

    static func makeApp(store: ComicSearchStore) throws -> AppState {
        let container = try ModelContainer(
            for: StoredComic.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return AppState(
            storedComicStore: StoredComicStore(context: container.mainContext),
            comicSearchStore: store,
            defaults: UserDefaults(suiteName: "search-index-tests-\(UUID())")!
        )
    }

    static var sampleComic: Comic {
        Comic(
            id: 42, title: "Sample Adventure", image: "", cover: "", description: "",
            author: "Test", keyword: "", follow: 0, view: 0, updateTime: .distantPast,
            isOver: false, score: 0)
    }
}
