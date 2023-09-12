import XCTest
@testable import tinys3

// swiftlint:disable line_length
final class CompleteMultipartUpload: XCTestCase, RequestTest {

    var request: AWSRequest = AWSRequest.completeMultipartUploadRequest(
        bucket: "examplebucket",
        key: "/test.txt",
        uploadId: "upload-id-example",
        hash: "123456",
        parts: [
            
        ],
        credentials: .testDefault,
        date: .testDefault
    )

    func testThatCanonicalUriIsCorrect() throws {
        XCTAssertEqual("/test.txt", request.canonicalUri)
    }

    func testThatCanonicalQueryStringIsCorrect() throws {
        XCTAssertEqual("uploadId=upload-id-example", request.canonicalQueryString)
    }

    func testThatCanonicalHeaderStringIsCorrect() throws {
//        XCTAssertEqual("""
//host:examplebucket.s3.amazonaws.com
//x-amz-content-sha256:fc7f05463bfcba9544b41d16d63e11dc7d00de382024d3c53cd2e7d112aac5c6
//x-amz-date:20130524T000000Z
//""", request.canonicalHeaderString)
    }

    func testThatSignedHeaderStringIsCorrect() throws {
        XCTAssertEqual("host;x-amz-content-sha256;x-amz-date", request.signedHeaderString)
    }

    func testThatCanonicalRequestIsValid() throws {
//        XCTAssertEqual("""
//POST
///test.txt
//uploadId=upload-id-example
//host:examplebucket.s3.amazonaws.com
//x-amz-content-sha256:fc7f05463bfcba9544b41d16d63e11dc7d00de382024d3c53cd2e7d112aac5c6
//x-amz-date:20130524T000000Z
//
//host;x-amz-content-sha256;x-amz-date
//fc7f05463bfcba9544b41d16d63e11dc7d00de382024d3c53cd2e7d112aac5c6
//""", request.canonicalRequest)
    }

    func testThatStringToSignIsValid() throws {
//        XCTAssertEqual("""
//AWS4-HMAC-SHA256
//20130524T000000Z
//20130524/us-east-1/s3/aws4_request
//cb0efeb959ff76146f084dd91c95b684144cf98ded4a8cbb2c8fa8ff4b446ae3
//""", request.stringToSign)
    }

    func testThatSignatureIsValid() throws {
//        XCTAssertEqual("0ffb25e4724b256784df98fe3b902ac82b33f50bed1d12c027e4a6f14d5522d0", request.signature)
    }

    func testThatAuthorizationHeaderValueIsCorrect() throws {
//        XCTAssertEqual("""
//AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=0ffb25e4724b256784df98fe3b902ac82b33f50bed1d12c027e4a6f14d5522d0
//""", request.authorizationHeaderValue)
    }

    func testThatPresignedURLIsCorrect() throws {
//        XCTAssertEqual("", request.presignedUrl.absoluteString)
    }

    func testThatEscapingEncodesXMLStructure() throws {
        let string: String = CompleteMultipartUploadRequestBodyBuilder()
            .addPart(.init(number: 1, eTag: "2ecc3a5a7ff81cadb982c43408c391c1"))
            .build(options: .escaped)

        XCTAssertEqual(string, try R.xmlString("EscapedCompleteMultipartBody"))
    }
}
