import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class Cache {
    private let statement: OpaquePointer?

    init(statement: OpaquePointer?) {
        self.statement = statement
    }

    func bind(text: String, at index: Int32) {
        sqlite3_bind_text(statement, index, text, -1, sqliteTransient)
    }

    func bind(data: Data, at index: Int32) {
        data.withUnsafeBytes { buffer in
            sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(buffer.count), sqliteTransient)
        }
    }
}
