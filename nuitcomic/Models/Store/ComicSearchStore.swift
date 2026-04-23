//
//  ComicSearchStore.swift
//  nuitcomic
//
//  Created by Zhongqiu Ruan on 2026/4/22.
//

import Foundation
import SQLite3

struct SearchStatus: Sendable {
    let comicCount: Int
    let lastSyncAt: Date?
}

actor ComicSearchStore {
    static let shared = ComicSearchStore()

    private let databaseURL: URL
    private var database: OpaquePointer?

    init(databaseURL: URL? = nil) {
        if let databaseURL {
            self.databaseURL = databaseURL
        } else {
            let supportDirectory = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            self.databaseURL =
                supportDirectory
                .appendingPathComponent("Search", isDirectory: true)
                .appendingPathComponent("comic_search.sqlite")
        }
    }

    deinit {
        sqlite3_close(database)
    }

    func status() throws -> SearchStatus {
        try prepareDatabaseIfNeeded()

        return SearchStatus(
            comicCount: try scalarInt(sql: "SELECT COUNT(*) FROM comic_search;"),
            lastSyncAt: try fetchLastSyncAt())
    }

    func replaceIndex(with comics: [Comic]) throws -> SearchStatus {
        try prepareDatabaseIfNeeded()
        try execute(sql: "BEGIN IMMEDIATE TRANSACTION;")

        do {
            try execute(sql: "DELETE FROM comic_search;")

            let insertSQL = """
                INSERT INTO comic_search (
                    comic_id, 
                    title,
                    author,
                    keyword,
                    description,
                    image,
                    cover,
                    follow,
                    view,
                    update_time,
                    is_over,
                    score
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?);           
                """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, insertSQL, -1, &statement, nil) == SQLITE_OK else {
                throw SearchDatabaseError.prepare(message: lastErrorMessage())
            }
            defer { sqlite3_finalize(statement) }

            for comic in comics {
                sqlite3_reset(statement)
                sqlite3_clear_bindings(statement)

                try bindInt64(Int64(comic.id), to: 1, in: statement)
                try bindText(comic.title, to: 2, in: statement)
                try bindText(comic.author, to: 3, in: statement)
                try bindText(comic.keyword, to: 4, in: statement)
                try bindText(comic.description, to: 5, in: statement)
                try bindText(comic.image, to: 6, in: statement)
                try bindText(comic.cover, to: 7, in: statement)
                try bindInt64(Int64(comic.follow), to: 8, in: statement)
                try bindInt64(comic.view, to: 9, in: statement)
                try bindDouble(
                    comic.updateTime.timeIntervalSince1970,
                    to: 10,
                    in: statement
                )
                try bindInt64(comic.isOver ? 1 : 0, to: 11, in: statement)
                try bindDouble(comic.score, to: 12, in: statement)

                guard sqlite3_step(statement) == SQLITE_DONE else {
                    throw SearchDatabaseError.step(message: lastErrorMessage())
                }
            }

            try upsertMetadata(key: "last_sync_at", value: String(Date().timeIntervalSince1970))
            try execute(sql: "COMMIT TRANSACTION;")
        } catch {
            try? execute(sql: "ROLLBACK TRANSACTION;")
            throw error
        }

        return try status()
    }

    func search(query: String, limit: Int? = nil) throws -> [Comic] {
        try prepareDatabaseIfNeeded()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let limitSQL =
            if let limit {
                " LIMIT \(limit)"
            } else {
                ""
            }

        let searchSQL = """
            WITH field_matches AS (
                SELECT
                    rowid,
                    0 AS match_priority,
                    bm25(comic_search, 10.0, 1.0, 1.0, 1.0) AS match_rank
                FROM comic_search
                WHERE comic_search MATCH ?

                UNION ALL

                SELECT
                    rowid,
                    1 AS match_priority,
                    bm25(comic_search, 1.0, 1.0, 1.0, 6.0) AS match_rank
                FROM comic_search
                WHERE comic_search MATCH ?

                UNION ALL

                SELECT
                    rowid,
                    2 AS match_priority,
                    bm25(comic_search, 1.0, 1.0, 4.0, 1.0) AS match_rank
                FROM comic_search
                WHERE comic_search MATCH ?

                UNION ALL

                SELECT
                    rowid,
                    3 AS match_priority,
                    bm25(comic_search, 1.0, 2.0, 1.0, 1.0) AS match_rank
                FROM comic_search
                WHERE comic_search MATCH ?

                UNION ALL

                SELECT
                    rowid,
                    0 AS match_priority,
                    1000000.0 AS match_rank
                FROM comic_search
                WHERE title LIKE ?

                UNION ALL

                SELECT
                    rowid,
                    1 AS match_priority,
                    1000001.0 AS match_rank
                FROM comic_search
                WHERE description LIKE ?

                UNION ALL

                SELECT
                    rowid,
                    2 AS match_priority,
                    1000002.0 AS match_rank
                FROM comic_search
                WHERE keyword LIKE ?

                UNION ALL

                SELECT
                    rowid,
                    3 AS match_priority,
                    1000003.0 AS match_rank
                FROM comic_search
                WHERE author LIKE ?
            ),
            best_matches AS (
                SELECT
                    rowid,
                    match_priority,
                    match_rank,
                    ROW_NUMBER() OVER (
                        PARTITION BY rowid
                        ORDER BY match_priority ASC, match_rank ASC
                    ) AS row_number
                FROM field_matches
            )
            SELECT
                comic_search.comic_id,
                comic_search.title,
                comic_search.image,
                comic_search.cover,
                comic_search.description,
                comic_search.author,
                comic_search.keyword,
                comic_search.follow,
                comic_search.view,
                comic_search.update_time,
                comic_search.is_over,
                comic_search.score
            FROM best_matches
            JOIN comic_search ON comic_search.rowid = best_matches.rowid
            WHERE best_matches.row_number = 1
            ORDER BY
                best_matches.match_priority ASC,
                best_matches.match_rank ASC,
                comic_search.update_time DESC
            \(limitSQL);
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, searchSQL, -1, &statement, nil) == SQLITE_OK else {
            throw SearchDatabaseError.prepare(message: lastErrorMessage())
        }
        defer { sqlite3_finalize(statement) }

        let escapedQuery = trimmedQuery.replacingOccurrences(of: "\"", with: "\"\"")
        let titleFTSQuery = "title : \"\(escapedQuery)\""
        let descriptionFTSQuery = "description : \"\(escapedQuery)\""
        let keywordFTSQuery = "keyword : \"\(escapedQuery)\""
        let authorFTSQuery = "author : \"\(escapedQuery)\""
        let likeQuery = "%\(trimmedQuery)%"

        try bindText(titleFTSQuery, to: 1, in: statement)
        try bindText(descriptionFTSQuery, to: 2, in: statement)
        try bindText(keywordFTSQuery, to: 3, in: statement)
        try bindText(authorFTSQuery, to: 4, in: statement)
        try bindText(likeQuery, to: 5, in: statement)
        try bindText(likeQuery, to: 6, in: statement)
        try bindText(likeQuery, to: 7, in: statement)
        try bindText(likeQuery, to: 8, in: statement)

        var comics: [Comic] = []
        while true {
            let stepResult = sqlite3_step(statement)
            if stepResult == SQLITE_DONE {
                break
            }
            guard stepResult == SQLITE_ROW else {
                throw SearchDatabaseError.step(message: lastErrorMessage())
            }

            comics.append(
                Comic(
                    id: Int(sqlite3_column_int64(statement, 0)),
                    title: stringValue(statement, column: 1),
                    image: stringValue(statement, column: 2),
                    cover: stringValue(statement, column: 3),
                    description: stringValue(statement, column: 4),
                    author: stringValue(statement, column: 5),
                    keyword: stringValue(statement, column: 6),
                    follow: Int(sqlite3_column_int64(statement, 7)),
                    view: sqlite3_column_int64(statement, 8),
                    updateTime: Date(timeIntervalSince1970: sqlite3_column_double(statement, 9)),
                    isOver: sqlite3_column_int64(statement, 10) == 1,
                    score: sqlite3_column_double(statement, 11)
                ))
        }

        return comics
    }

    private func prepareDatabaseIfNeeded() throws {
        guard database == nil else { return }

        let directoryURL = databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        guard sqlite3_open(databaseURL.path, &database) == SQLITE_OK else {
            defer { sqlite3_close(database) }
            throw SearchDatabaseError.open(message: lastErrorMessage())
        }

        try execute(sql: "PRAGMA journal_mode = WAL;")
        try execute(sql: "PRAGMA synchronous = NORMAL;")
        try execute(sql: "PRAGMA temp_store = MEMORY;")

        try execute(
            sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS comic_search USING fts5(
                    comic_id UNINDEXED,
                    title,
                    author,
                    keyword,
                    description,
                    image UNINDEXED,
                    cover UNINDEXED,
                    follow UNINDEXED,
                    view UNINDEXED,
                    update_time UNINDEXED,
                    is_over UNINDEXED,
                    score UNINDEXED,
                    tokenize = 'unicode61 remove_diacritics 0'
                );
                """)

        try execute(
            sql: """
                CREATE TABLE IF NOT EXISTS search_metadata (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );
                """)
    }

    private func execute(sql: String) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw SearchDatabaseError.execute(message: lastErrorMessage())
        }
    }

    private func lastErrorMessage() -> String {
        guard let database, let message = sqlite3_errmsg(database) else {
            return "Unknown SQLite error"
        }
        return String(cString: message)
    }

    private func upsertMetadata(key: String, value: String) throws {
        let sql = """
            INSERT INTO search_metadata (key, value)
            VALUES (?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value;
            """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SearchDatabaseError.prepare(message: lastErrorMessage())
        }
        defer { sqlite3_finalize(statement) }

        try bindText(key, to: 1, in: statement)
        try bindText(value, to: 2, in: statement)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SearchDatabaseError.step(message: lastErrorMessage())
        }
    }

    private func fetchLastSyncAt() throws -> Date? {
        let sql = "SELECT value FROM search_metadata WHERE key = ? LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK
        else {
            throw SearchDatabaseError.prepare(message: lastErrorMessage())
        }
        defer { sqlite3_finalize(statement) }

        try bindText("last_sync_at", to: 1, in: statement)
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }

        let rawValue = stringValue(statement, column: 0)
        guard let seconds = Double(rawValue) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    private func scalarInt(sql: String) throws -> Int {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SearchDatabaseError.prepare(message: lastErrorMessage())
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw SearchDatabaseError.step(message: lastErrorMessage())
        }

        return Int(sqlite3_column_int64(statement, 0))
    }

    private func stringValue(_ statement: OpaquePointer?, column: Int32) -> String {
        guard let rawValue = sqlite3_column_text(statement, column) else {
            return ""
        }
        return String(cString: rawValue)
    }

    private func bindText(_ value: String, to index: Int32, in statement: OpaquePointer?) throws {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        guard sqlite3_bind_text(statement, index, value, -1, transient) == SQLITE_OK
        else {
            throw SearchDatabaseError.bind(message: lastErrorMessage())
        }
    }

    private func bindInt64(_ value: Int64, to index: Int32, in statement: OpaquePointer?) throws {
        guard sqlite3_bind_int64(statement, index, value) == SQLITE_OK else {
            throw SearchDatabaseError.bind(message: lastErrorMessage())
        }
    }

    private func bindDouble(_ value: Double, to index: Int32, in statement: OpaquePointer?) throws {
        guard sqlite3_bind_double(statement, index, value) == SQLITE_OK else {
            throw SearchDatabaseError.bind(message: lastErrorMessage())
        }
    }
}

private enum SearchDatabaseError: LocalizedError {
    case open(message: String)
    case execute(message: String)
    case prepare(message: String)
    case bind(message: String)
    case step(message: String)

    var errorDescription: String? {
        switch self {
        case .open(let message):
            return "打开搜索数据库失败：\(message)"
        case .execute(let message):
            return "执行搜索数据库语句失败：\(message)"
        case .prepare(let message):
            return "准备搜索数据库语句失败：\(message)"
        case .bind(let message):
            return "绑定搜索参数失败：\(message)"
        case .step(let message):
            return "读取搜索结果失败：\(message)"
        }
    }
}
