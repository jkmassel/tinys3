import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct AWSRequest {
    let verb: HTTPMethod
    let bucket: String
    let path: String?
    let credentials: AWSCredentials
    let queryItems: [URLQueryItem]
    let headers: HttpHeaders
    let date: Date

    private let endpoint: S3Endpoint

    // MARK: Derived Properties
    private let contentHash: String
    private let scope: AWSScope
    private let signer: AWSRequestSigner

    init(
        verb: HTTPMethod,
        bucket: String,
        path: String,
        credentials: AWSCredentials,
        body: Data = Data(),
        queryItems: [URLQueryItem] = [],
        headers: HttpHeaders = HttpHeaders(),
        date: Date = Date(),
        endpoint: S3Endpoint = .default
    ) {
        self.verb = verb
        self.bucket = bucket
        self.path = path

        self.contentHash = sha256Hash(data: body)
        self.scope = AWSScope(region: credentials.region, date: date)
        self.signer = AWSRequestSigner(credentials: credentials, requestDate: date)

        self.credentials = credentials
        self.endpoint = endpoint
        self.queryItems = queryItems

        let headerCopy = headers
        self.headers = headerCopy.adding([
            .host: self.endpoint.hostname(forBucket: bucket, inRegion: credentials.region),
            .xAmxContentSha256: self.contentHash,
            .xAmzDate: formattedTimestamp(from: date)
        ])
        self.date = date
    }

    var canonicalRequest: String {
        [
            self.verb.rawValue,
            self.path,
            self.queryItems.asEscapedQueryString,
            self.headers.canonicalized,
            "", // Yep, there's supposed to be an extra blank line here
            self.headers.signed,
            self.contentHash
        ]
            .compactMap { $0 }
            .joined(separator: "\n")
    }

    var stringToSign: String {
        [
            "AWS4-HMAC-SHA256",
            formattedTimestamp(from: self.date),
            self.scope.description,
            sha256Hash(string: canonicalRequest)
        ].joined(separator: "\n")
    }

    var authorizationHeaderValue: String {
        "AWS4-HMAC-SHA256 " + [
            "Credential=\(self.credentials.accessKeyId)/\(self.scope.description)",
            "SignedHeaders=\(self.headers.signed)",
            "Signature=\(signer.sign(string: stringToSign))"
        ].joined(separator: ",")
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = self.endpoint.scheme.rawValue
        components.host = self.endpoint.hostname(forBucket: self.bucket, inRegion: self.credentials.region)

        if !self.queryItems.isEmpty {
            components.queryItems = self.queryItems
        }

        if let path = self.path {
            components.path = path.starts(with: "/") ? path : "/" + path
        }

        if let port = self.endpoint.port {
            components.port = port
        }

        return components.url!
    }

    var urlRequest: URLRequest {
        var urlRequest = URLRequest(url: self.url)
        urlRequest.httpMethod = self.verb.rawValue
        urlRequest.allHTTPHeaderFields = self.headers
            .adding(.authorization, value: self.authorizationHeaderValue)
            .toHttpHeaderFields

        return urlRequest
    }
}

extension AWSRequest {
    static func listRequest(
        bucketName: String,
        prefix: String = "",
        credentials: AWSCredentials,
        date: Date = Date(),
        endpoint: S3Endpoint = .default
    ) -> AWSRequest {

        AWSRequest(
            verb: .get,
            bucket: bucketName,
            path: endpoint.usesBucketSubdomains ? "/" : "/\(bucketName)/",
            credentials: credentials,
            queryItems: [
                URLQueryItem(name: "prefix", value: prefix)
            ],
            date: date,
            endpoint: endpoint
        )
    }
}
