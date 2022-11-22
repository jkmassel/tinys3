import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct S3HeadResponse {

    struct Constants {
        static let ContentLengthKey = "Content-Length"
        static let ETagKey = "Etag"
        static let LastModifiedKey = "Last-Modified"
    }

    let key: String
    let response: HTTPURLResponse

    public var s3Object: S3Object? {
        let modificationDateParser = DateFormatter()
        modificationDateParser.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"

        guard
            let contentLengthString = response.value(forHTTPHeaderField: Constants.ContentLengthKey),
            let contentLength = Int(contentLengthString),
            let eTag = response.value(forHTTPHeaderField: Constants.ETagKey),
            let lastModifiedString = response.value(forHTTPHeaderField: Constants.LastModifiedKey),
            let lastModifiedAt = modificationDateParser.date(from: lastModifiedString)
        else {
            return nil
        }

        return S3Object(
            key: self.key,
            size: contentLength,
            eTag: eTag,
            lastModifiedAt: lastModifiedAt,
            storageClass: ""
        )
    }

    static func from(key: String, response: AWSResponse) -> S3HeadResponse {
        .init(key: key, response: response.response)
    }

    static func from(key: String, response: HTTPURLResponse) -> S3HeadResponse {
        .init(key: key, response: response)
    }
}
