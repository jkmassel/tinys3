import XCTest
@testable import tinys3

final class AWSCredentialsTests: XCTestCase {

    let credentials: AWSCredentials = .testDefault

    func testThatCredentialsFromFileReturnsNilForMissingFile() throws {
        let invalidURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        XCTAssertNil(try AWSCredentials.from(url: invalidURL))
    }
}
