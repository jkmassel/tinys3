import Foundation

@available(macOS 10.15.4, *)
struct MultipartUploadOperation {
    let bucket: String
    let key: String
    let path: URL
    let credentials: AWSCredentials

    struct AWSUploadPart {
        let number: Int
        let range: Range<Int>
    }

    struct AWSPartData {
        let uploadId: String
        let number: Int
        let data: Data

        init(uploadId: String, number: Int, data: Data) {
            self.uploadId = uploadId
            self.number = number
            self.data = data
        }

        var md5Hash: String {
            tinys3.md5Hash(data: data)
        }

        var sha256Hash: String {
            tinys3.sha256Hash(data: data)
        }
    }

    struct AWSUploadedPart: Comparable {
        let number: Int
        let eTag: String

        static func < (lhs: MultipartUploadOperation.AWSUploadedPart, rhs: MultipartUploadOperation.AWSUploadedPart) -> Bool {
            lhs.number < rhs.number
        }
    }

    actor MultipartUploadFile {
        private let handle: FileHandle

        init(path: URL) throws {
            self.handle = try FileHandle(forReadingFrom: path)
        }

        subscript(range: Range<Int>) -> Data {
            get throws {
                try handle.seek(toOffset: UInt64(range.lowerBound))

                guard let data = try handle.read(upToCount: range.count) else {
                    throw CocoaError(.fileReadUnknown)
                }

                return data
            }
        }
    }

    private let file: MultipartUploadFile

    private let fileSize: Int
    private let partSize: Int

    private var progress: Progress

    init(bucket: String, key: String, path: URL, credentials: AWSCredentials) throws {
        self.bucket = bucket
        self.key = key
        self.path = path
        self.credentials = credentials

        self.file = try MultipartUploadFile(path: path)
        self.fileSize = try FileManager.default.fileSize(of: path)
        self.partSize = max(5_000_000, min(4_900_000_000, self.fileSize / 12))
        self.progress = Progress(totalUnitCount: Int64(self.fileSize))
    }

    func start(progress: ProgressCallback? = nil) async throws {
        let createRequest = AWSRequest.createMultipartUploadRequest(
            bucket: bucket,
            key: key,
            path: path,
            credentials: self.credentials
        )

        let createResponse = try S3CreateMultipartUploadResponse.from(response: await perform(createRequest).validate())
        let uploadId = createResponse.uploadId

        let parts = calculateParts(forFileWithSize: fileSize)

        let uploadedParts = try await parts.parallelMap(parallelism: 8) {
            let result = try await uploadPart(withUploadId: uploadId, forRange: $0.range, atIndex: $0.number)

            self.progress.completedUnitCount += Int64(self.partSize)
            progress?(self.progress)

            return result
        }

        let requestData: Data = CompleteMultipartUploadRequestBodyBuilder().addPart(uploadedParts.first!).build()
        let requestHash = sha256Hash(data: requestData)

        let finalizeRequest = AWSRequest.completeMultipartUploadRequest(
            bucket: bucket,
            key: key,
            uploadId: uploadId,
            hash: requestHash,
            parts: uploadedParts,
            credentials: self.credentials
        )

        try await upload(finalizeRequest, with: requestData).validate()
    }

    func uploadPart(
        withUploadId uploadId: String,
        forRange range: Range<Int>,
        atIndex index: Int
    ) async throws -> AWSUploadedPart {

        let part = AWSPartData(
            uploadId: uploadId,
            number: index,
            data: try await file[range]
        )

        let request = try AWSRequest.uploadPartRequest(
            bucket: bucket,
            key: key,
            part: part,
            credentials: self.credentials
        )

        let response = try await upload(request, with: part.data).validate()

        guard let eTag = response.value(forHTTPHeaderField: "Etag") else {
            throw CocoaError(.propertyListReadUnknownVersion)
        }

        return AWSUploadedPart(number: part.number, eTag: eTag)
    }

    func calculateParts(forFileWithSize size: Int) -> [AWSUploadPart] {
        var rangeStart = 0
        var rangeEnd = -1

        var parts = [AWSUploadPart]()
        var partNumber = 1

        while(rangeEnd < size) {
            rangeStart = (parts.last?.range.upperBound ?? -1) + 1
            rangeEnd = rangeStart + partSize

            parts.append(.init(number: partNumber, range: rangeStart..<rangeEnd))
            partNumber += 1
        }

        return parts
    }

    func calculateFileChecksum(forFileAt path: URL) async throws -> String {
        return try await Task { try sha256Hash(fileAt: path) }.value
    }

    func perform(_ request: AWSRequest, with body: Data? = nil) async throws -> AWSResponse {
        var urlRequest = request.urlRequest
        urlRequest.timeoutInterval = 3600

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        return try AWSResponse(response: response as? HTTPURLResponse, data: data)
    }

    func upload(_ request: AWSRequest, with body: Data) async throws -> AWSResponse {
        var urlRequest = request.urlRequest
        urlRequest.timeoutInterval = 3600

        let (data, response) = try await URLSession.shared.upload(for: urlRequest, from: body)
        return try AWSResponse(response: response as? HTTPURLResponse, data: data)
    }
}
extension Collection {
    func parallelMap<T>(parallelism: Int, _ transform: @escaping (Element) async throws -> T) async throws -> [T] {

        let n = self.count

        if n == 0 {
            return []
        }

        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            var result = Array<T?>(repeatElement(nil, count: n))

            var i = self.startIndex
            var submitted = 0

            func submitNext() async throws {
                if i == self.endIndex { return }

                group.addTask { [submitted, i] in
                    let value = try await transform(self[i])
                    return (submitted, value)
                }

                submitted += 1
                formIndex(after: &i)
            }

            // submit first initial tasks
            for _ in 0..<parallelism {
                try await submitNext()
            }

            // as each task completes, submit a new task until we run out of work
            while let (index, taskResult) = try await group.next() {
                result[index] = taskResult

                try Task.checkCancellation()
                try await submitNext()
            }

            assert(result.count == n)
            return Array(result.compactMap { $0 })
        }
    }
}
