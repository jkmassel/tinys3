import Foundation

public struct AWSCredentials: Equatable {

    let accessKeyId: String
    let secretKey: String
    let region: String

    public init(accessKeyId: String, secretKey: String, region: String) {
        self.accessKeyId = accessKeyId
        self.secretKey = secretKey
        self.region = region
    }

    public static func fromUserConfiguration(profile: AWSProfile = .default) throws -> AWSCredentials? {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".aws")
            .appendingPathComponent("credentials")

        return try from(url: url, profile: profile)
    }

    public static func from(url: URL, profile: AWSProfile = .default) throws -> AWSCredentials? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let credentialsFile = try AWSCredentialsFileParser(path: url).parse()
        return credentialsFile[profile.name]
    }
}

public struct AWSProfile {
    let name: String

    public static func custom(name: String) -> AWSProfile {
        return AWSProfile(name: name)
    }

    public static let `default` = AWSProfile(name: "default")
}
