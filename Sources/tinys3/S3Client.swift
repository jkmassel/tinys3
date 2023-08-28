import Foundation
import OSLog
import Crypto

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct S3Client {

    private let credentials: AWSCredentials
    private let endpoint: S3Endpoint
    private let urlSession: URLSession

    public init(credentials: AWSCredentials, endpoint: S3Endpoint = .default, urlSession: URLSession = .shared) {
        self.credentials = credentials
        self.endpoint = endpoint
        self.urlSession = urlSession

        if #available(macOS 11.0, *) {
            Logger(OSLog.default).info("Created S3 Client")
            Logger(OSLog.default).info("S3 Client Access Key ID: \(credentials.accessKeyId, privacy: .public)")
            Logger(OSLog.default).info("S3 Client Secret Key: \(credentials.secretKey, privacy: .private)")
            Logger(OSLog.default).info("S3 Client Region: \(credentials.region, privacy: .public)")
        }
    }

    public func head(bucket: String, key: String) async throws -> S3HeadResponse {
        let url = AWSPresignedDownloadURL(
            bucket: bucket,
            key: key,
            ttl: 60,
            credentials: self.credentials
        ).url

        let request = URLRequest(url: url)

        let (data, response) = try await perform(request: request)
        try AWSResponse(response: response, data: data).validate()

        return S3HeadResponse.from(key: key, response: response)
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
        progressCallback: ProgressCallback? = nil
    ) async throws -> URL {
        let url = signedDownloadUrl(forKey: key, in: bucket, validFor: 60)
        return try await DownloadOperation(url: url).start(progressCallback: progressCallback)
    }

    public func stream(
        objectWithKey key: String,
        inBucket bucket: String,
        progressCallback: ProgressCallback? = nil,
        headersCallback: StreamingDownloadOperation.HeadersCallback? = nil,
        dataCallback: StreamingDownloadOperation.DataCallback? = nil
    ) async throws -> URL {
        let temporaryUrl = FileManager.default
            .temporaryDirectory
            .appendingPathComponent( UUID().uuidString)

        let downloadOperation = StreamingDownloadOperation(
            url: signedDownloadUrl(forKey: key, in: bucket, validFor: 60)
        )

        downloadOperation.headersCallback = headersCallback
        downloadOperation.dataCallback = dataCallback
        downloadOperation.progressCallback = progressCallback

        try await downloadOperation.start(tempPath: temporaryUrl)

        return temporaryUrl
    }

//    @available(macOS 12.0, *)
//    public func signedUploadRequest(
//        forFileAt path: URL,
//        key: String,
//        inBucket bucket: String,
//        validFor timeInterval: TimeInterval
//    ) throws -> URLRequest {
////        AWSUrlSigningRequest(
////            verb: .put,
////            bucket: bucket,
////            key: key,
////            contentSignature: try sha256Hash(fileAt: path),
////            ttl: timeInterval,
////            credentials: self.credentials,
////            endpoint: self.endpoint
////        ).urlRequest
//    }

//    @available(macOS 12.0, *)
//    public func upload(
//        objectAtPath path: URL,
//        toBucket bucket: String,
//        key: String
//    ) async throws {
//        let request = try signedUploadRequest(forFileAt: path, key: key, inBucket: bucket, validFor: 3600)
//        let result = try await self.urlSession.upload(for: request, fromFile: path)
//
//        debugPrint(result)
//    }

    func perform(request: AWSRequest) async throws -> AWSResponse {
        let (data, response) = try await perform(request: request.urlRequest)
        return try AWSResponse(response: response, data: data)
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
