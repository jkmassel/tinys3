import XCTest
@testable import tinys3

final class HttpByteRangeTests: XCTestCase {
    func testThatUnevenGroupingWorksCorrectly() throws {
        XCTAssertEqual(
            HttpByteRange.grouped(forByteCount: 48, intoNumberOfGroups: 5),
            [0...8, 9...17, 18...26, 27...35, 36...48].map(HttpByteRange.init)
        )
    }

    func testThatEvenGroupingWorksCorrectly() throws {
        XCTAssertEqual(
            HttpByteRange.grouped(forByteCount: 49, intoNumberOfGroups: 7),
            [0...6, 7...13, 14...20, 21...27, 28...34, 35...41, 42...49].map(HttpByteRange.init)
        )
    }

    func testThatCaddyProvidedByteRangeCanBeParsed() throws {
        XCTAssertEqual(
            HttpByteRange.from(httpHeaderValue: "bytes 2639265798-3079143430/4398776320"),
            HttpByteRange(lowerBound: 2639265798, upperBound: 3079143430)
        )
    }

    func testThatArbitraryFailureCase1WorksCorrectly() throws {
        XCTAssertEqual(
            HttpByteRange.grouped(forByteCount: 64, intoNumberOfGroups: 20),
            [
                0...2, 3...5, 6...8, 9...11, 12...14, 15...17, 18...20,
                21...23, 24...26, 27...29, 30...32, 33...35, 36...38, 39...41,
                42...44, 45...47, 48...50, 51...53, 54...56, 57...64
            ].map(HttpByteRange.init)
        )

    }
}


// 15902720
