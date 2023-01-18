import XCTest
@testable import tinys3

final class HttpByteRangeTests: XCTestCase {
    func testThatUnevenGroupingWorksCorrectly() throws {
        XCTAssertEqual(
            HttpByteRange.grouped(forByteCount: 48, intoNumberOfGroups: 5),
            [0...9, 10...19, 20...29, 30...39, 40...48].map(HttpByteRange.init)
        )
    }

    func testThatEvenGroupingWorksCorrectly() throws {
        XCTAssertEqual(
            HttpByteRange.grouped(forByteCount: 49, intoNumberOfGroups: 7),
            [0...7, 8...15, 16...23, 24...31, 32...39, 40...47, 48...49].map(HttpByteRange.init)
        )
    }

    func testThatCaddyProvidedByteRangeCanBeParsed() throws {
        XCTAssertEqual(
            HttpByteRange.from(httpHeaderValue: "bytes 2639265798-3079143430/4398776320"),
            HttpByteRange(lowerBound: 2639265798, upperBound: 3079143430)
        )
    }
}


// 15902720
