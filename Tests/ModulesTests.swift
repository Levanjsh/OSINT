import XCTest
import OSLog
@testable import OSINTScout

final class ModulesTests: XCTestCase {
    func testDNSModuleSummary() async throws {
        let records = [DNSRecord(name: "example.com.", type: 1, data: "93.184.216.34", ttl: 300)]
        let module = DNSRecordsModule { _ in MockDNSClient(records: records) }
        let settingsStore = SettingsStore(logger: Logger(subsystem: "tests", category: "settings"))
        let http = HTTPClient(settingsStore: settingsStore, logger: Logger(subsystem: "tests", category: "http"))
        let cache = Cache(logger: Logger(subsystem: "tests", category: "cache"))
        let context = ModuleContext(http: http, cache: cache, settings: .default, logger: Logger(subsystem: "tests", category: "module"))
        let result = try await module.run(on: .domain("example.com"), using: context)
        XCTAssertTrue(result.summary.contains("DNS"))
        XCTAssertEqual(result.artifacts.count, 1)
        XCTAssertEqual(result.artifacts.first?.value, "93.184.216.34")
    }
}

struct MockDNSClient: DNSResolving {
    let records: [DNSRecord]

    func resolve(host: String, type: Int) async throws -> [DNSRecord] {
        records.filter { $0.type == type }
    }
}
