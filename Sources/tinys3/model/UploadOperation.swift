import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class UploadOperation: NSObject {

    private let request: URLRequest
    private let path: URL
    private let urlSessionConfiguration: URLSessionConfiguration
    private lazy var session: URLSession = URLSession(
        configuration: self.urlSessionConfiguration,
        delegate: self,
        delegateQueue: nil
    )
    private lazy var task: URLSessionUploadTask = session.uploadTask(with: self.request, fromFile: self.path)

    private var uploadContinuation: CheckedContinuation<Void, Error>!
    private var progressCallback: ProgressCallback?
    private var startDate: Date!

    init(request: URLRequest, path: URL, urlSessionConfiguration: URLSessionConfiguration = .default) {
        self.urlSessionConfiguration = urlSessionConfiguration
        self.path = path
        self.request = request
    }

    func start(progressCallback: ProgressCallback? = nil) async throws {
        self.progressCallback = progressCallback

        return try await withCheckedThrowingContinuation { continuation in
            self.startDate = Date()
            self.uploadContinuation = continuation

            self.task.resume()
        }
    }
}

extension UploadOperation: URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error {
            self.uploadContinuation.resume(throwing: error)
        }
    }
}

extension UploadOperation: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            self.uploadContinuation.resume(throwing: error)
        } else {
            self.uploadContinuation.resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        self.progressCallback?(task.uploadProgress(givenStartDate: self.startDate))
    }
}

extension URLSessionTask {

    func downloadProgress(givenStartDate startDate: Date) -> Progress {
        let now = Date()
        let elapsedTime = now.timeIntervalSince(startDate)

        let progress = Progress(totalUnitCount: self.countOfBytesExpectedToReceive)
        progress.completedUnitCount = self.countOfBytesReceived
        progress.kind = .file
        progress.setUserInfoObject(Progress.FileOperationKind.downloading.rawValue, forKey: .fileOperationKindKey)
        progress.estimateThroughput(fromTimeElapsed: elapsedTime)

        return progress
    }

    func uploadProgress(givenStartDate startDate: Date) -> Progress {
        let now = Date()
        let elapsedTime = now.timeIntervalSince(startDate)

        let progress = Progress(totalUnitCount: self.countOfBytesExpectedToSend)
        progress.completedUnitCount = self.countOfBytesSent
        progress.kind = .file
//        progress.setUserInfoObject(Progress.FileOperationKind.uploading.rawValue, forKey: .fileOperationKindKey)
        progress.estimateThroughput(fromTimeElapsed: elapsedTime)

        return progress
    }
}
