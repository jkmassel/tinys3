import Foundation

struct HttpByteRange: Equatable {
    let rawValue: ClosedRange<Int64>

    var representationForHttpHeader: String {
        "bytes=\(rawValue.lowerBound)-\(rawValue.upperBound)"
    }

    var count: Int64 {
        rawValue.upperBound - rawValue.lowerBound
    }

    var lowerBound: Int64 {
        rawValue.lowerBound
    }

    var upperBound: Int64 {
        rawValue.upperBound
    }

    init(startingWith size: Int64) {
        self.rawValue = 0...size
    }

    init(lowerBound: Int, upperBound: Int) {
        self.rawValue = Int64(lowerBound)...Int64(upperBound)
    }

    init(lowerBound: Int64, upperBound: Int64) {
        self.rawValue = lowerBound...upperBound
    }

    init(rawValue: ClosedRange<Int64>) {
        self.rawValue = rawValue
    }

    static func grouped(forByteCount byteCount: Int64, intoNumberOfGroups numberOfGroups: Int) -> [HttpByteRange] {
        let chunkSize = byteCount.quotientAndRemainder(dividingBy: Int64(numberOfGroups))

        var count: Int64 = -1
        var pieces = [ClosedRange<Int64>]()

        for _ in 0..<numberOfGroups - 1 {
            let lowerBound = count + 1
            let upperBound = lowerBound + chunkSize.quotient

            pieces.append(lowerBound...upperBound)

            count = upperBound
        }

        pieces.append((count + 1)...byteCount)

        return pieces.map(HttpByteRange.init)
    }

    static func from(httpHeaderValue string: String) -> HttpByteRange? {
        guard
            string.starts(with: "bytes"),
            let bytesRange = string.range(of: "bytes "),
            let indexOfDash = string.range(of: "-"),
            let indexOfSlash = string.range(of: "/")
        else {
            return nil
        }

        let lowerBoundString = string[bytesRange.upperBound..<indexOfDash.lowerBound]
        let upperBoundString = string[indexOfDash.upperBound..<indexOfSlash.lowerBound]

        guard
            let lowerBound = Int(lowerBoundString),
            let upperBound = Int(upperBoundString)
        else {
            return nil
        }

        return HttpByteRange(lowerBound: lowerBound, upperBound: upperBound)
    }
}
