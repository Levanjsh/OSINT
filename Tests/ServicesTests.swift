import XCTest
@testable import OSINTScout

final class ServicesTests: XCTestCase {
    func testEscapeWrapsAndDoublesQuotes() {
        let exporter = CSVExporter()
        let value = "He said \"Hello\""
        XCTAssertEqual(exporter.escape(value), "\"He said \"\"Hello\"\"\"")
    }

    func testExportHandlesMultilineValues() {
        let exporter = CSVExporter()
        let rows = [["Line1\nLine2", "value"], ["plain", "another"]]
        let expected = "\"Line1\nLine2\",value\nplain,another"
        XCTAssertEqual(exporter.export(rows: rows), expected)
    }
}
