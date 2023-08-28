import Foundation
import XCTest
import tinys3

struct TestPlan {
    var credentials: AWSCredentials
    var endpoint: S3Endpoint
    var bucket: String

    var fileToDownload: String
    var expectedSizeOfFileToDownload: Int
}

let minioTestPlan = TestPlan(
    credentials: AWSCredentials(
        accessKeyId: "minioadmin",
        secretKey: "minioadmin",
        region: "us-east-1"
    ), endpoint: .custom(
        domain: "localhost",
        port: 9000,
        usesHttps: false,
        usesBucketSubdomains: false
    ),
    bucket: "my-test-bucket",
    fileToDownload: "book.txt",
    expectedSizeOfFileToDownload: 1234
)

let s3DefaultTestPlan = TestPlan(
    // swiftlint:disable force_try
    credentials: try! .fromUserConfiguration(),
    endpoint: .default,
    bucket: "a8c-repo-mirrors",
    fileToDownload: "automattic/simplenote-ios/2022-11-03.git.tar",
    expectedSizeOfFileToDownload: 15902720
)

let s3AcceleratedTestPlan = TestPlan(
    // swiftlint:disable force_try
    credentials: try! .fromUserConfiguration(),
    endpoint: .accelerated,
    bucket: "a8c-repo-mirrors",
    fileToDownload: "automattic/simplenote-ios/2022-11-03.git.tar",
    expectedSizeOfFileToDownload: 15902720
)

class S3DefaultTestPlan: XCTestCase {
    var testPlan: TestPlan { s3DefaultTestPlan }

    var s3Client: S3Client {
        S3Client(credentials: self.testPlan.credentials, endpoint: self.testPlan.endpoint)
    }

//    func testThatBucketContentsCanBeListed() async throws {
//        let result = try await s3Client.list(bucket: testPlan.bucket)
//        XCTAssertGreaterThan(result.objects.count, 0)
//    }

    func testThatObjectCanBeReadWithLeadingSlash() async throws {
        let result = try await s3Client.head(
            bucket: testPlan.bucket,
            key: "/" + testPlan.fileToDownload
        )
        XCTAssertNotNil(result.s3Object)
        XCTAssertEqual(result.s3Object?.size, testPlan.expectedSizeOfFileToDownload)
    }

    func testThatObjectCanBeReadWithoutLeadingSlash() async throws {
        let result = try await s3Client.head(
            bucket: testPlan.bucket,
            key: testPlan.fileToDownload
        )

        XCTAssertNotNil(result.s3Object)
        XCTAssertEqual(result.s3Object?.size, testPlan.expectedSizeOfFileToDownload)
    }

    func testThatObjectCanBeDownloadedWithLeadingSlash() async throws {
        let result = try await s3Client.download(
            objectWithKey: "/" + testPlan.fileToDownload,
            inBucket: testPlan.bucket
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    func testThatObjectCanBeDownloadedWithoutLeadingSlash() async throws {
        let result = try await s3Client.download(
            objectWithKey: testPlan.fileToDownload,
            inBucket: testPlan.bucket
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    func testThatObjectStreamingSendsDataToCallback() async throws {
        var dataReceived = 0
        _ = try await s3Client.stream(
            objectWithKey: testPlan.fileToDownload,
            inBucket: testPlan.bucket,
            dataCallback: { dataReceived += $0.count }
        )

        XCTAssertEqual(dataReceived, testPlan.expectedSizeOfFileToDownload)
    }

    func testThatObjectStreamingStoresFileLocally() async throws {
        let result = try await s3Client.stream(
            objectWithKey: testPlan.fileToDownload,
            inBucket: testPlan.bucket
        )

        XCTAssertEqual(
            try FileManager.default.attributesOfItem(atPath: result.path)[.size] as? Int,
            testPlan.expectedSizeOfFileToDownload
        )
    }

//    func testThatUploadWorks() async throws {
//        let client = try S3Client(credentials: .fromUserConfiguration())
//        let uploadUrl = try client.signedUploadRequest(
//            forFileAt: URL(fileURLWithPath: "/private/var/folders/v_/fzlwrt9n3c9bz17s467wz6980000gn/T/xcrun_db"),
//            key: "foo",
//            inBucket: "a8c-ci-cache",
//            validFor: 3600
//        )
//
//        print(uploadUrl.url, uploadUrl.allHTTPHeaderFields)
//    }
}

final class S3AcceleratedEndpointTests: S3DefaultTestPlan {
    override var testPlan: TestPlan { s3AcceleratedTestPlan }
}
