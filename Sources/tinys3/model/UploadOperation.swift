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

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.progressCallback?(task.uploadProgress(givenStartDate: self.startDate))
    }
}

//extension UploadOperation:  {
//
//    func urlSession(
//        _ session: URLSession,
//        downloadTask: URLSessionDownloadTask,
//        didWriteData bytesWritten: Int64,
//        totalBytesWritten: Int64,
//        totalBytesExpectedToWrite: Int64
//    ) {
//        self.progressCallback?(downloadTask.progress(givenStartDate: self.startDate))
//    }
//
//    func urlsession
//
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        do{
//            // It's easier to debug issues if the file name is recognizable, but in unlikely circumstances where
//            // the filename *isn't* available, we'll use a UUID
//            let filename = self.request.url?.lastPathComponent ?? UUID().uuidString
//
//            // It's possible for the download to fail after this method completes, but before our temp destination file
//            // is moved to its final location. In this case, a retry would cause an error unless the temp destination
//            // has a unique name – to handle that case, we'll append a unique suffix to the filenam
//            let destination = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
//                .appendingPathExtension(String(UUID().uuidString.prefix(6)))
//                .appendingPathExtension("tmp")
//
//            try FileManager.default.moveItem(at: location, to: destination)
//            self.uploadContinuation.resume()
//        } catch {
//            self.uploadContinuation.resume(throwing: error)
//        }
//    }
//}

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
        progress.setUserInfoObject(Progress.FileOperationKind.uploading.rawValue, forKey: .fileOperationKindKey)
        progress.estimateThroughput(fromTimeElapsed: elapsedTime)

        return progress
    }
}
