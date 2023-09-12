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

    private var progressCallback: ProgressCallback?
    private var startDate: Date!

    init(request: URLRequest, path: URL, urlSessionConfiguration: URLSessionConfiguration = .default) {
        self.urlSessionConfiguration = urlSessionConfiguration
        self.path = path
        self.request = request
    }

    @available(macOS 12.0, *)
    func start(progressCallback: ProgressCallback? = nil) async throws {
        self.progressCallback = progressCallback
        self.startDate = Date()

        let (data, rawResponse) = try await self.session.upload(for: request, fromFile: path, delegate: self)
        try AWSResponse(response: rawResponse as? HTTPURLResponse, data: data).validate()
    }
}

extension UploadOperation: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let now = Date()
        let elapsedTime = now.timeIntervalSince(startDate)

        let progress = Progress(totalUnitCount: task.countOfBytesExpectedToSend)
        progress.completedUnitCount = task.countOfBytesSent
        progress.kind = .file
        progress.setUserInfoObject(Progress.FileOperationKind.uploading.rawValue, forKey: .fileOperationKindKey)
        progress.estimateThroughput(fromTimeElapsed: elapsedTime)

        self.progressCallback?(task.progress)
    }
}
