import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public typealias ProgressCallback = (Progress) -> Void

class DownloadOperation: NSObject {

    private let request: URLRequest
    private let urlSessionConfiguration: URLSessionConfiguration
    private lazy var session: URLSession = URLSession(
        configuration: self.urlSessionConfiguration,
        delegate: self,
        delegateQueue: nil
    )
    private lazy var task: URLSessionDownloadTask = session.downloadTask(with: self.request)

    private var downloadContinuation: CheckedContinuation<URL, Error>!
    private var progressCallback: ProgressCallback?
    private var startDate: Date!

    init(url: URL, urlSessionConfiguration: URLSessionConfiguration = .default) {
        self.urlSessionConfiguration = urlSessionConfiguration
        self.request = URLRequest(url: url)
    }

    func start(progressCallback: ProgressCallback? = nil) async throws -> URL {
        self.progressCallback = progressCallback

        return try await withCheckedThrowingContinuation { continuation in
            self.startDate = Date()
            self.downloadContinuation = continuation

            self.task.resume()
        }
    }
}

extension DownloadOperation: URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error {
            self.downloadContinuation.resume(throwing: error)
        }
    }
}

extension DownloadOperation: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            self.downloadContinuation.resume(throwing: error)
        }
    }
}

extension DownloadOperation: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        self.progressCallback?(downloadTask.progress(givenStartDate: self.startDate))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.downloadContinuation.resume(returning: location)
    }
}

extension URLSessionDownloadTask {
    func progress(givenStartDate startDate: Date) -> Progress {
        let now = Date()
        let elapsedTime = now.timeIntervalSince(startDate)

        let progress = Progress(totalUnitCount: self.countOfBytesExpectedToReceive)
        progress.completedUnitCount = self.countOfBytesReceived
        progress.kind = .file
        progress.setUserInfoObject(Progress.FileOperationKind.downloading.rawValue, forKey: .fileOperationKindKey)
        progress.estimateThroughput(fromTimeElapsed: elapsedTime)

        return progress
    }
}
