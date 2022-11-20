import XCTest
@testable import tinys3

final class HttpHeadersTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
    }

    func testThatHeadersAreCorrectlyCanonicalized() throws {
        let headers = HttpHeaders([
            .host: "my-test-bucket.s3.us-east-1.amazonaws.com",
            .xAmxContentSha256: sha256Hash(data: Data()),
            .xAmzDate: formattedTimestamp(from: .testDefault)
        ])

        let expectedHeaders = """
host:my-test-bucket.s3.us-east-1.amazonaws.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20150830T183600Z
""".trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertEqual(expectedHeaders, headers.canonicalized)
    }

    func testThatHeadersAreCorrectlyOutputForSigning() throws {
        let headers = HttpHeaders([
            .host: "my-test-bucket.s3.us-east-1.amazonaws.com",
            .xAmxContentSha256: sha256Hash(data: Data()),
            .xAmzDate: formattedTimestamp(from: .testDefault)
        ])

        let expectedHeaders = "host;x-amz-content-sha256;x-amz-date"
        XCTAssertEqual(expectedHeaders, headers.signed)
    }
}
