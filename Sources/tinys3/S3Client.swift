import Foundation
import Crypto

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(OSLog)
import OSLog
#endif

public struct S3Client {

    private let credentials: AWSCredentials
    private let endpoint: S3Endpoint
    private let urlSession: URLSession

    public init(credentials: AWSCredentials, endpoint: S3Endpoint = .default, urlSession: URLSession = .shared) {
        self.credentials = credentials
        self.endpoint = endpoint
        self.urlSession = urlSession

        #if canImport(OSLog)
        if #available(macOS 11.0, *) {
            Logger(OSLog.default).info("Created S3 Client")
            Logger(OSLog.default).info("S3 Client Access Key ID: \(credentials.accessKeyId, privacy: .public)")
            Logger(OSLog.default).info("S3 Client Secret Key: \(credentials.secretKey, privacy: .private)")
            Logger(OSLog.default).info("S3 Client Region: \(credentials.region, privacy: .public)")
        }
        #endif
    }

    public func head(bucket: String, key: String) async throws -> S3Object? {
        let url = AWSPresignedDownloadURL(
            verb: .head,
            bucket: bucket,
            key: key,
            ttl: 60,
            credentials: self.credentials
        ).url

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        let (data, response) = try await perform(request: request)
        let awsResponse = try AWSResponse(response: response, data: data).validate()

        return S3HeadResponse.from(key: key, response: awsResponse).s3Object
    }

    public func list(bucket: String, prefix: String = "") async throws -> S3ListResponse {
        let request = AWSRequest.listRequest(
            bucket: bucket,
            prefix: prefix,
            credentials: self.credentials
        )

        let response = try await perform(request: request).validate()
        return try S3ListResponse.from(response: response)
    }

    public func signedDownloadUrl(forKey key: String, in bucket: String, validFor timeInterval: TimeInterval) -> URL {
        AWSPresignedDownloadURL(
            bucket: bucket,
            key: key,
            ttl: timeInterval,
            credentials: self.credentials
        ).url
    }

    public func download(
        objectWithKey key: String,
        inBucket bucket: String,
        progressCallback: ProgressCallback? = nil,
        endpoint: S3Endpoint = .default
    ) async throws -> URL {
        let request = AWSRequest.downloadRequest(
            bucket: bucket,
            key: key,
            credentials: self.credentials,
            endpoint: endpoint
        ).urlRequest

        return try await DownloadOperation(request: request).start(progressCallback: progressCallback)
    }

    public func upload(
        objectAtPath path: URL,
        toBucket bucket: String,
        key: String,
        progressCallback: ProgressCallback? = nil
    ) async throws {
        let operation = try MultipartUploadOperation(
            bucket: bucket,
            key: key,
            path: path,
            credentials: self.credentials
        )

        try await operation.start(progressCallback)
    }

    func perform(request: AWSRequest) async throws -> AWSResponse {
        let (data, response) = try await perform(request: request.urlRequest)
        return try AWSResponse(response: response, data: data).validate()
    }

    func perform(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        return try await withCheckedThrowingContinuation { continuation -> Void in
            let task = self.urlSession.dataTask(with: request) { data, response, networkError in
                if let error = networkError {
                    continuation.resume(throwing: error)
                    return
                }

                if let data = data, let response = response as? HTTPURLResponse {
                    continuation.resume(with: .success((data, response)))
                    return
                }

                if let response = response as? HTTPURLResponse {
                    continuation.resume(with: .success((Data(), response)))
                    return
                }

                abort()
            }

            task.resume()
        }
    }
}
