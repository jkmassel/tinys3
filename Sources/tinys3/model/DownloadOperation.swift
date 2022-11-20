import Foundation

public typealias ProgressCallback = (Progress) -> Void

class DownloadOperation: NSObject {

    private let request: URLRequest
    private let session: URLSession

    init(url: URL, urlSession: URLSession = .shared) {
        self.request = URLRequest(url: url)
        self.session = urlSession
    }

    func start(progressCallback: ProgressCallback? = nil) async throws -> URL {
        let startDate = Date()

        var observation: NSKeyValueObservation?

        let url: URL = try await withCheckedThrowingContinuation { continuation in
            let task = self.session.downloadTask(with: self.request) { url, _, error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                    return
                }

                if let url = url {
                    continuation.resume(with: .success(url))
                    return
                }
            }

            observation = task.observe(\.countOfBytesReceived) { task, _ in
                progressCallback?(task.progress(givenStartDate: startDate))
            }

            task.resume()
        }

        observation?.invalidate()

        return url
    }
}

extension URLSessionDownloadTask {
    func progress(givenStartDate startDate: Date) -> Progress {
        let now = Date()
        let elapsedTime = now.timeIntervalSince(startDate)

        let progress = Progress(totalUnitCount: self.countOfBytesExpectedToReceive)
        progress.completedUnitCount = self.countOfBytesReceived
        progress.kind = .file
        progress.fileOperationKind = .downloading
        progress.estimateThroughput(fromTimeElapsed: elapsedTime)

        return progress
    }
}
