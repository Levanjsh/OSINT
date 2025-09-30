import Foundation

public struct CSVExporter {
    public let delimiter: Character

    public init(delimiter: Character = ",") {
        self.delimiter = delimiter
    }

    /// Escapes a raw value so it can be safely embedded in a CSV file.
    /// - Parameter value: The unescaped cell value.
    /// - Returns: The escaped representation following RFC 4180 rules.
    public func escape(_ value: String) -> String {
        guard !value.isEmpty else { return value }

        let mustQuote = value.contains(delimiter) ||
            value.contains("\"") ||
            value.contains("\n") ||
            value.contains("\r")

        guard mustQuote else {
            return value
        }

        let doubledQuotes = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(doubledQuotes)\""
    }

    /// Converts the provided rows into a CSV string using the configured delimiter.
    /// - Parameter rows: Collection of rows, each row being a collection of cell values.
    /// - Returns: A CSV formatted string.
    public func export(rows: [[String]]) -> String {
        rows
            .map { row in
                row.map(escape).joined(separator: String(delimiter))
            }
            .joined(separator: "\n")
    }
}
