import XCTest
import Foundation
import Crypto
import tinys3

let testBucketName = "my-test-bucket"
let testObjectKey = "/my/path/to/stuff.txt"
let testPrefix = "my/path/"

extension AWSCredentials {
    /// Valid, but deleted credentials – created only for use with this project, then destroyed immediately.
    static let testDefault = AWSCredentials(
        accessKeyId: "AKIATNTB7DC3QVYVRJ2Y",
        secretKey: "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",
        region: "us-east-1"
    )
}

extension Date {
    static var testDefault: Date {
        Date(timeIntervalSince1970: 1440959760)
    }
}

// swiftlint:disable type_name
struct R {
    static func string(_ name: String) throws -> String {
        return try String(contentsOf: url(forResourceName: name, withExtension: "txt"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func xmlData(_ name: String) throws -> Data {
        return try Data(contentsOf: url(forResourceName: name, withExtension: "xml"))
    }

    private static func url(forResourceName name: String, withExtension ext: String) throws -> URL {
        let desc = "There's no file named \(name).\(ext) in the module – you might need to register it in Package.swift"

        guard let url = Bundle.module.url(forResource: name, withExtension: ext) else {
            throw ResourceNotFoundError(errorDescription: desc)
        }

        return url
    }

    struct ResourceNotFoundError: LocalizedError {
        let errorDescription: String
    }

    struct AWSCredentialsFile {
        static var multiple: String { get throws { try R.string("aws-credentials-file-multiple") } }
        static var single: String { get throws { try R.string("aws-credentials-file-single") } }
    }
}
