import XCTest
@testable import tinys3

final class ListRequestTests: XCTestCase {

    let defaultRequest = AWSRequest.listRequest(
        bucketName: testBucketName,
        credentials: .testDefault,
        date: .testDefault
    )

    let prefixRequest = AWSRequest.listRequest(
        bucketName: testBucketName,
        prefix: "/my/path/",
        credentials: .testDefault,
        date: .testDefault
    )

    let acceleratedRequest = AWSRequest.listRequest(
        bucketName: testBucketName,
        credentials: .testDefault,
        endpoint: .accelerated
    )

    /// This allows us to list all objects in a bucket
    func testThatAWSRequestsUseEmptyStringForPrefixByDefault() {
        XCTAssertEqual("", defaultRequest.queryItems["prefix"])
    }

    /// We currently use a leading "/" in the path for AWS to avoid signature errors
    func testThatAWSRequestsUseEmptyPathByDefault() {
        XCTAssertEqual("/", defaultRequest.path)
        XCTAssertEqual("/", prefixRequest.path)
    }

    func testThatHostnameUsesBucketSubdomainForAWSRequests() throws {
        XCTAssertEqual("my-test-bucket.s3.us-east-1.amazonaws.com", defaultRequest.url.host)
        XCTAssertEqual("my-test-bucket.s3.us-east-1.amazonaws.com", prefixRequest.url.host)
        XCTAssertEqual("my-test-bucket.s3-accelerate.amazonaws.com", acceleratedRequest.url.host)
    }

    func testThatCanonicalRequestIsValid() throws {
        let expected = try R.string("default-list-request-canonical-request")
        XCTAssertEqual(expected, prefixRequest.canonicalRequest)
    }

    func testThatStringToSignIsValid() throws {
        let expected = try R.string("default-list-request-string-to-sign")
        XCTAssertEqual(expected, defaultRequest.stringToSign)
    }

    func testThatAuthorizationHeaderIsValid() throws {
        let expected = try R.string("default-list-request-authorization-header")
        XCTAssertEqual(expected, defaultRequest.authorizationHeaderValue)
    }
}
