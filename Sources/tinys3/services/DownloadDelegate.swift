import Foundation

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {

    enum Errors: Error {
        case invalidResponse
    }

    private let taskId: String
    private let continuation: CheckedContinuation<URL, Error>
    private let startDate = Date()

    var progress = Progress()

    var progressDidChange: (() -> Void)?

    init(taskId: String, continuation: CheckedContinuation<URL, Error>) {
        self.taskId = taskId
        self.continuation = continuation
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            continuation.resume(throwing: error)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let destination = try moveDownloadedFile(at: location, forTask: downloadTask)
            self.continuation.resume(returning: destination)
        } catch {
            self.continuation.resume(throwing: error)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        guard totalBytesWritten % 10 == 0 else {
            return
        }

        self.ensureParentTaskHasNotBeenCancelled(task: downloadTask)
        self.updateProgress(forTask: downloadTask)
        self.progressDidChange?()
    }

    func moveDownloadedFile(at url: URL, forTask task: URLSessionDownloadTask) throws -> URL {
        let tempPath = tempPath(forTask: task)
        try FileManager.default.moveItem(at: url, to: tempPath)
        return tempPath
    }

    func tempPath(forTask task: URLSessionDownloadTask) -> URL {
        var fileName = ""

        if let expectedFileName = task.originalRequest?.url?.lastPathComponent {
            fileName.append(expectedFileName + "-")
        }

        fileName.append(self.taskId)

        var tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        if let description = task.taskDescription {
            tempPath.appendPathExtension(description)
        }

        return tempPath.appendingPathExtension("tmp")
    }

    func updateProgress(forTask task: URLSessionDownloadTask) {
        let now = Date()
        let elapsedTime = now.timeIntervalSince(self.startDate)

        self.progress.totalUnitCount = task.countOfBytesExpectedToReceive
        self.progress.completedUnitCount = task.countOfBytesReceived
        self.progress.kind = .file
        self.progress.setUserInfoObject(Progress.FileOperationKind.downloading.rawValue, forKey: .fileOperationKindKey)
        self.progress.estimateThroughput(fromTimeElapsed: elapsedTime)
    }

    func ensureParentTaskHasNotBeenCancelled(task: URLSessionDownloadTask) {
        do {
            try Task.checkCancellation()
        } catch {
            task.cancel()
            self.continuation.resume(throwing: error)
        }
    }
}
