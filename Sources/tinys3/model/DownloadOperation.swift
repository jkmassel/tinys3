import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public typealias ProgressCallback = (Progress) -> Void

public class DownloadOperation: NSObject {

    internal let url: URL
    internal let urlSession: URLSession

    internal let taskId = String.random(length: 8)

    private var downloadContinuation: CheckedContinuation<URL, Error>!
    private var progressCallback: ProgressCallback?
    private var startDate: Date!

    public init(url: URL, urlSession: URLSession = .shared) {
        self.url = url
        self.urlSession = urlSession
    }

    public func start(progressCallback: ProgressCallback? = nil) async throws -> URL {
        self.progressCallback = progressCallback
        return try await download(url: self.url)
    }

    func download(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation {
            let delegate = DownloadDelegate(taskId: self.taskId, continuation: $0)
            delegate.progressDidChange = { self.progressCallback?(delegate.progress) }

            let task = self.urlSession.downloadTask(with: URLRequest(url: url))
            task.delegate = delegate
            task.resume()
        }
    }
}
