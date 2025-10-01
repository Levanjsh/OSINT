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

    func testHTTPHeadersModuleParsesResponse() async throws {
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: "HTTP/2", headerFields: [
            "Server": "TestServer",
            "Content-Type": "text/html"
        ])!
        let module = HTTPHeadersModule { _, _ in response }
        let settingsStore = SettingsStore(logger: Logger(subsystem: "tests", category: "settings"))
        let http = HTTPClient(settingsStore: settingsStore, logger: Logger(subsystem: "tests", category: "http"))
        let cache = Cache(logger: Logger(subsystem: "tests", category: "cache"))
        let context = ModuleContext(http: http, cache: cache, settings: .default, logger: Logger(subsystem: "tests", category: "module"))
        let result = try await module.run(on: .domain("example.com"), using: context)
        XCTAssertTrue(result.summary.contains("200"))
        XCTAssertTrue(result.artifacts.contains { $0.title == "Server" })
    }

    func testRobotsModuleExtractsRules() async throws {
        let data = "User-agent: *\nDisallow: /private\nAllow: /public\n".data(using: .utf8)!
        let module = RobotsModule { _, _ in data }
        let settingsStore = SettingsStore(logger: Logger(subsystem: "tests", category: "settings"))
        let http = HTTPClient(settingsStore: settingsStore, logger: Logger(subsystem: "tests", category: "http"))
        let cache = Cache(logger: Logger(subsystem: "tests", category: "cache"))
        let context = ModuleContext(http: http, cache: cache, settings: .default, logger: Logger(subsystem: "tests", category: "module"))
        let result = try await module.run(on: .domain("example.com"), using: context)
        XCTAssertEqual(result.artifacts.count, 3)
        XCTAssertTrue(result.summary.contains("3"))
    }
}

struct MockDNSClient: DNSResolving {
    let records: [DNSRecord]

    func resolve(host: String, type: Int) async throws -> [DNSRecord] {
        records.filter { $0.type == type }
    }
}
