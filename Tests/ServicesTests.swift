import XCTest
@testable import OSINTScout

final class ServicesTests: XCTestCase {
    func testDNSDecoding() throws {
        let data = try fixture(named: "dns_response")
        let response = try JSONDecoder().decode(DNSResponse.self, from: data)
        XCTAssertEqual(response.status, 0)
        XCTAssertEqual(response.answer?.first?.data, "93.184.216.34")
    }

    func testNvdDecoding() throws {
        let data = try fixture(named: "nvd_response")
        let response = try JSONDecoder().decode(NVDResponse.self, from: data)
        XCTAssertEqual(response.vulnerabilities.count, 1)
        XCTAssertEqual(response.vulnerabilities.first?.cve.id, "CVE-2023-0001")
    }

    private func fixture(named name: String) throws -> Data {
        let url = Bundle(for: type(of: self)).url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        guard let url else { throw NSError(domain: "Fixture", code: 0) }
        return try Data(contentsOf: url)
    }
}
