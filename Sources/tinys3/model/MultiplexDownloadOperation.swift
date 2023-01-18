import Foundation

public class MultiplexDownloadOperation: DownloadOperation {

    private let contentLength: Int64

    let progress: Progress

    init(url: URL, contentLength: Int64) {
        self.contentLength = contentLength
        self.progress = Progress(totalUnitCount: contentLength)
        super.init(url: url)
    }

    override func start(progressCallback: ProgressCallback? = nil) async throws -> URL {

        // Swift's concurrency system only allows one concurrent task per machine core, so there's no
        // benefit to allocating more tasks than that. What's more – on the iOS simulator, only one cooperative
        // multitasking thread is allowed per-process
        let concurrencyLevel = ProcessInfo.processInfo.isSimulator ? 1 : ProcessInfo.processInfo.processorCount

        let tempPaths = try await withThrowingTaskGroup(of: URL.self) { group in
            let byteRanges = HttpByteRange.grouped(
                forByteCount: self.contentLength,
                intoNumberOfGroups: concurrencyLevel
            )

            for (index, range) in byteRanges.enumerated() {
                group.addTask {
                    try await self.download(
                        byteRange: range,
                        atIndex: index,
                        forUrl: self.url,
                        progressCallback: progressCallback
                    )
                }
            }

            return try await group.collect().sorted()
        }

        let destination = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(self.url.lastPathComponent)
            .appendingPathExtension(self.taskId)
            .appendingPathExtension("tmp")

        let fileMerger = FileMerger(sources: tempPaths)
        self.progress.addChild(fileMerger.progress, withPendingUnitCount: self.contentLength)
        try fileMerger.merge(into: destination)

        return destination
    }

    func download(byteRange: HttpByteRange, atIndex index: Int, forUrl: URL, progressCallback: ProgressCallback? = nil) async throws -> URL {
        try await withCheckedThrowingContinuation {
            let delegate = DownloadDelegate(taskId: self.taskId, continuation: $0)
            delegate.progressDidChange = { progressCallback?(self.progress) }
            self.progress.addChild(delegate.progress, withPendingUnitCount: byteRange.count)

            var request = URLRequest(url: url)
            request.byteRange = byteRange
            // We don't have control over when urlsessiond will schedule these downloads, so we can't assume a timeout
            request.timeoutInterval = .infinity

            let task = self.urlSession.downloadTask(with: request)
            task.delegate = delegate
            task.taskDescription = String(index)
            task.resume()
        }
    }
}
