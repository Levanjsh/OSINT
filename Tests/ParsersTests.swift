import XCTest
@testable import OSINTScout

final class ParsersTests: XCTestCase {
    func testDomainValidation() throws {
        XCTAssertTrue(Validators.isValidDomain("example.com"))
        XCTAssertFalse(Validators.isValidDomain("invalid_domain"))
    }

    func testEmailValidation() throws {
        XCTAssertTrue(Validators.isValidEmail("user@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user@"))
    }

    func testEntityParsing() throws {
        let entity = try Entity.parse(input: "Example.com", type: .domain)
        if case let .domain(value) = entity {
            XCTAssertEqual(value, "example.com")
        } else {
            XCTFail("Expected domain entity")
        }
    }
}
