import Foundation

public struct S3Object: Equatable {
    public let key: String
    public let size: Int
    public let eTag: String
    public let lastModifiedAt: Date
    public let storageClass: String

    enum Errors: Error {
        case invalidResponse
    }

    static func from(_ response: HTTPURLResponse, forKey key: String) throws -> S3Object {
        let modificationDateParser = DateFormatter()
        modificationDateParser.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"

        let contentLength = response.expectedContentLength

        guard
            contentLength > 0,
            let eTag = response.value(forHTTPHeaderField: .eTag),
            let lastModifiedString = response.value(forHTTPHeaderField: .lastModified),
            let lastModifiedAt = modificationDateParser.date(from: lastModifiedString)
        else {
            throw Errors.invalidResponse
        }

        return S3Object(
            key: key,
            size: contentLength,
            eTag: eTag,
            lastModifiedAt: lastModifiedAt,
            storageClass: ""
        )
    }
}

extension S3Object: Comparable {
    public static func < (lhs: S3Object, rhs: S3Object) -> Bool {
        lhs.key < rhs.key
    }
}
