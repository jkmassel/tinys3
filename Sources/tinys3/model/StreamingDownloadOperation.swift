import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class StreamingDownloadOperation: NSObject {

    public typealias HeadersCallback = ([String: String]) -> Void
    public typealias DataCallback = (Data) -> Void
    public typealias ProgressCallback = (Progress) -> Void

    private let request: URLRequest

    private lazy var session: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: nil
    )

    private lazy var task: URLSessionTask = session.dataTask(with: self.request)
    private var fileHandle: FileHandle!

    private var continuation: CheckedContinuation<Void, Error>!

    public var progressCallback: ProgressCallback?
    public var dataCallback: DataCallback?
    public var headersCallback: HeadersCallback?

    public init(url: URL) {
        self.request = URLRequest(url: url)
        super.init()
    }

    public init(request: URLRequest) {
        self.request = request
        super.init()
    }

    public func start(tempPath: URL) async throws {
        try createTempFile(at: tempPath)

        self.fileHandle = try FileHandle(forWritingTo: tempPath)

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.task.resume()
        }
    }

    private func createTempFile(at path: URL) throws {
        try FileManager.default.createDirectory(
            at: path.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        }

        FileManager.default.createFile(atPath: path.path, contents: nil)
    }
}

extension StreamingDownloadOperation: URLSessionTaskDelegate {

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error = error else {
            return
        }

        self.continuation.resume(throwing: error)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        do { try self.fileHandle.close() } catch { self.continuation.resume(throwing: error) }

        if let error {
            self.continuation.resume(throwing: error)
            return
        }

        self.continuation.resume()
    }
}

extension StreamingDownloadOperation: URLSessionDataDelegate {

    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {

        if let response = response as? HTTPURLResponse {
            self.headersCallback?(HttpHeaders(from: response).toHttpHeaderFields)
        }

        return .allow
    }

    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        self.fileHandle.write(data)
        self.dataCallback?(data)
        self.progressCallback?(dataTask.progress)
    }
}
