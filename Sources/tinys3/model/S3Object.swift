import Foundation

public struct S3Object {
    public let key: String
    public let size: Int
    public let eTag: String
    public let lastModifiedAt: Date
    public let storageClass: String
}
