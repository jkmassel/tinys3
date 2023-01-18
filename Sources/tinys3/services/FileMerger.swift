import Foundation

/// An object that appends the contents of a source file to a destination file
struct FileMerger {

    struct Constants {
        // There's not much benefit to a larger buffer – our bottleneck seems to be disk speed while concatenating
        // files, not context switching in the kernel
        static let bufferSize: Int = 65_536
    }

    enum Errors: Error {
        case UnableToReadFile
    }

    var progress: Progress = Progress()
    var progressDidChange: (() -> Void)?

    private var sources: [URL]

    init(sources: [URL] = []) {
        self.sources = sources
    }

    mutating func addSource(_ url: URL) throws {
        self.sources.append(url)
        try self.recalculateTotalProgress()
    }

    mutating func addSources(_ urls: [URL]) throws {
        self.sources.append(contentsOf: urls)
        try self.recalculateTotalProgress()
    }

    func merge(into destination: URL) throws {
        var buf = [UInt8](repeating: 0, count: Constants.bufferSize)

        guard let outputStream = OutputStream(url: destination, append: true) else {
            throw Errors.UnableToReadFile
        }

        outputStream.open()

        for source in self.sources {
            guard let sourceStream = InputStream(url: source) else {
                throw Errors.UnableToReadFile
            }

            sourceStream.open()

            while case let amount = sourceStream.read(&buf, maxLength: Constants.bufferSize), amount > 0 {
                outputStream.write(&buf, maxLength: amount)
                self.progress.completedUnitCount += Int64(amount)
                self.progressDidChange?()
            }

            sourceStream.close()

            try FileManager.default.removeItem(at: source)
        }

        outputStream.close()
    }

    func recalculateTotalProgress() throws {
        self.progress.totalUnitCount = try self.sources.compactMap {
            try FileManager.default.attributesOfItem(atPath: $0.path)[.size] as? Int64
        }.reduce(0, +)

        self.progressDidChange?()
    }
}
