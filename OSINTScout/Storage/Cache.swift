import Foundation
import OSLog
import SQLite3

final class Cache {
    private let dbPointer: OpaquePointer?
    private let logger: Logger
    private let queue = DispatchQueue(label: "cache.queue")

    init(logger: Logger) {
        self.logger = logger
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("osintscout-cache.sqlite")
        var db: OpaquePointer?
        if sqlite3_open(url.path, &db) != SQLITE_OK {
            logger.error("Unable to open cache database")
            dbPointer = nil
            return
        }
        dbPointer = db
        let createSQL = "CREATE TABLE IF NOT EXISTS cache (key TEXT PRIMARY KEY, value BLOB, timestamp REAL);"
        if sqlite3_exec(db, createSQL, nil, nil, nil) != SQLITE_OK {
            logger.error("Unable to create cache table")
        }
    }

    deinit {
        if let dbPointer {
            sqlite3_close(dbPointer)
        }
    }

    func store(key: String, value: Data) {
        guard let dbPointer else { return }
        queue.sync {
            let sql = "INSERT OR REPLACE INTO cache (key, value, timestamp) VALUES (?, ?, ?);"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK {
                key.withCString { pointer in
                    sqlite3_bind_text(statement, 1, pointer, -1, SQLITE_TRANSIENT)
                }
                sqlite3_bind_blob(statement, 2, (value as NSData).bytes, Int32(value.count), SQLITE_TRANSIENT)
                sqlite3_bind_double(statement, 3, Date().timeIntervalSince1970)
                if sqlite3_step(statement) != SQLITE_DONE {
                    logger.error("Failed to store cache for key \(key, privacy: .public)")
                }
            }
            sqlite3_finalize(statement)
        }
    }

    func fetch(key: String, maxAge: TimeInterval) -> Data? {
        guard let dbPointer else { return nil }
        return queue.sync {
            let sql = "SELECT value, timestamp FROM cache WHERE key = ?;"
            var statement: OpaquePointer?
            var result: Data?
            if sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK {
                key.withCString { pointer in
                    sqlite3_bind_text(statement, 1, pointer, -1, SQLITE_TRANSIENT)
                }
                if sqlite3_step(statement) == SQLITE_ROW {
                    let timestamp = sqlite3_column_double(statement, 1)
                    if Date().timeIntervalSince1970 - timestamp <= maxAge {
                        if let bytes = sqlite3_column_blob(statement, 0) {
                            let length = Int(sqlite3_column_bytes(statement, 0))
                            result = Data(bytes: bytes, count: length)
                        }
                    }
                }
            }
            sqlite3_finalize(statement)
            return result
        }
    }

    func clear() {
        guard let dbPointer else { return }
        queue.sync {
            sqlite3_exec(dbPointer, "DELETE FROM cache;", nil, nil, nil)
        }
    }
}
