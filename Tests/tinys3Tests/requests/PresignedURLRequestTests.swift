import XCTest
@testable import tinys3

final class PresignedURLRequestTests: XCTestCase {

    let defaultEndpointRequest = AWSUrlSigningRequest(
        verb: .get,
        bucket: "my-test-bucket",
        key: "/path/to/my/file.txt",
        ttl: 3600,
        credentials: .testDefault,
        date: .testDefault
    )

    func testThatDefaultEndpointCanonicalRequestIsValid() throws {
        let expected = try R.string("presigned-url-default-endpoint-canonical-request")
        XCTAssertEqual(expected, defaultEndpointRequest.canonicalRequest)
    }

    func testThatDefaultEndpointStringToSignIsValid() throws {
        let expected = try R.string("presigned-url-default-endpoint-string-to-sign")
        XCTAssertEqual(expected, defaultEndpointRequest.stringToSign)
    }

    func testThatDefaultEndpointSignatureIsValid() throws {
        XCTAssertEqual(
            "e8574d24a001f58ea23ec061aa9e5d6c10a21bc71a1f5972c48e7b44660e0b1d",
            defaultEndpointRequest.signature
        )
    }

    func testThatDefaultEndpointUrlIsValid() throws {
        let expected = try R.string("presigned-url-default-endpoint-url")

        XCTAssertEqual(
            try XCTUnwrap(URL(string: expected)),
            try XCTUnwrap(defaultEndpointRequest.presignedUrl)
        )
    }

    func testThatKeyIsNormalizedWithLeadingSlash() throws {
        let request = createTestRequest(bucket: "test-bucket", key: "test-key")
        XCTAssertEqual("/test-key", request.normalizedKey)
    }

    func testThatAcceleratedEndpointUrlIsValid() throws {
        let request = createTestRequest(bucket: "test-bucket", key: "test-key", endpoint: .accelerated)
        let expectedURL = try R.string("presigned-url-accelerated-endpoint-url")
        XCTAssertEqual(try XCTUnwrap(URL(string: expectedURL)), try XCTUnwrap(request.presignedUrl))
    }

    private func createTestRequest(
        bucket: String,
        key: String,
        endpoint: S3Endpoint = .default,
        ttl: TimeInterval = 3600,
        credentials: AWSCredentials = .testDefault,
        date: Date = .testDefault
    ) -> AWSUrlSigningRequest {
        AWSUrlSigningRequest(
            verb: .get,
            bucket: bucket,
            key: key,
            ttl: ttl,
            credentials: credentials,
            date: date,
            endpoint: endpoint
        )
    }
}
