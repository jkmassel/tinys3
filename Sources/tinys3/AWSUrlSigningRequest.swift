import Foundation

struct AWSUrlSigningRequest {
    let verb: HTTPMethod
    let bucket: String
    let key: String
    let credentials: AWSCredentials
    let date: Date
    let ttl: TimeInterval

    private let endpoint: S3Endpoint

    // MARK: Derived Properties
    private let scope: AWSScope
    private let signer: AWSRequestSigner
    private let headers: HttpHeaders
    private let queryItems: [URLQueryItem]

    init(
        verb: HTTPMethod,
        bucket: String,
        key: String,
        ttl: TimeInterval,
        credentials: AWSCredentials,
        date: Date = Date(),
        endpoint: S3Endpoint = .default
    ) {
        self.verb = verb
        self.bucket = bucket
        self.key = key
        self.credentials = credentials
        self.date = date
        self.ttl = ttl

        self.endpoint = endpoint

        self.scope = AWSScope(region: credentials.region, date: date)
        self.signer = AWSRequestSigner(credentials: credentials, requestDate: date)
        self.headers = HttpHeaders([
            .host: self.endpoint.hostname(forBucket: bucket, inRegion: credentials.region)
        ])
        self.queryItems = [
            URLQueryItem(name: "X-Amz-Algorithm", value: "AWS4-HMAC-SHA256"),
            URLQueryItem(name: "X-Amz-Content-Sha256", value: "UNSIGNED-PAYLOAD"),
            URLQueryItem(name: "X-Amz-Credential", value: "\(credentials.accessKeyId)/\(self.scope)"),
            URLQueryItem(name: "X-Amz-Date", value: formattedTimestamp(from: date)),
            URLQueryItem(name: "X-Amz-Expires", value: String(Int(ttl))),
            URLQueryItem(name: "X-Amz-SignedHeaders", value: "host"),
            URLQueryItem(name: "x-id", value: "GetObject")
        ]
    }

    var normalizedKey: String {
        var key = self.key

        if !key.starts(with: "/") {
            key = "/" + key
        }

        return key
    }

    var canonicalRequest: String {
        [
            self.verb.rawValue,
            self.normalizedKey,
            self.queryItems.asEscapedQueryString,
            self.headers.canonicalized,
            "", // Yep, there's supposed to be an extra blank line here
            "host",
            "UNSIGNED-PAYLOAD"
        ].joined(separator: "\n")
    }

    var stringToSign: String {
        [
            "AWS4-HMAC-SHA256",
            formattedTimestamp(from: self.date),
            self.scope.description,
            sha256Hash(string: canonicalRequest)
        ].joined(separator: "\n")
    }

    var signature: String {
        self.signer.sign(string: self.stringToSign)
    }

    var signatureQueryItem: URLQueryItem {
        URLQueryItem(name: "X-Amz-Signature", value: self.signature)
    }

    var presignedUrl: URL {
        var components = URLComponents()
        components.scheme = self.endpoint.scheme.rawValue
        components.host = self.endpoint.hostname(forBucket: self.bucket, inRegion: self.credentials.region)
        components.path = self.normalizedKey
        components.percentEncodedQueryItems = (self.queryItems.escaped + [signatureQueryItem]).sorted()

        if let port = self.endpoint.port {
            components.port = port
        }

        return components.url!
    }

    var urlRequest: URLRequest {
        var request = URLRequest(url: self.presignedUrl)
        request.httpMethod = self.verb.rawValue

        return request
    }
}
