import Foundation
import Crypto

struct InvalidDataError: Error {}

struct XMLDataValidator {

    var expectedRootElementName: String
    var wasTriggered: Bool = false

    mutating func validate(elementName: String, failureHandler: (Error) -> Void) {
        guard !wasTriggered else {
            return
        }

        self.wasTriggered = true

        guard elementName == expectedRootElementName else {
            failureHandler(InvalidDataError())
            return
        }
    }
}

func sha256Hash(data: Data) -> String {
    var hasher = SHA256()
    hasher.update(data: data)

    return hasher
        .finalize()
        .reduce(into: Data()) { $0.append($1) }
        .hexEncodedString()
}

func sha256Hash(string: String) -> String {
    sha256Hash(data: Data(string.utf8))
}

func formattedTimestamp(from date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    return formatter.string(from: date)
}

func formattedDatestamp(from date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    formatter.dateFormat = "yyyyMMdd"
    return formatter.string(from: date)
}

func parseLastModifiedDate(_ string: String) -> Date? {
    let modificationDateParser = DateFormatter()
    modificationDateParser.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
    return modificationDateParser.date(from: string)
}

func parseISO8601String(_ string: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: string)
}

extension Progress {

    #if(canImport(FoundationNetworking))
    // These methods don't exist in the Linux version of Foundation, so we implement them ourselves
    var throughput: Int? {
        self.userInfo[.throughputKey] as? Int
    }

    var estimatedTimeRemaining: TimeInterval? {
        self.userInfo[.estimatedTimeRemainingKey] as? TimeInterval
    }
    #endif

    func estimateThroughput(fromTimeElapsed elapsedTime: TimeInterval) {
        let unitsPerSecond = self.completedUnitCount.quotientAndRemainder(dividingBy: Int64(elapsedTime)).quotient
        let throughput = Int(unitsPerSecond)
        self.setUserInfoObject(throughput, forKey: .throughputKey)

        guard throughput > 0 else {
            return
        }

        let unitsRemaining = self.totalUnitCount - self.completedUnitCount
        let secondsRemaining = unitsRemaining.quotientAndRemainder(dividingBy: Int64(throughput)).quotient

        self.setUserInfoObject(TimeInterval(secondsRemaining), forKey: .estimatedTimeRemainingKey)
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"
}

extension URLQueryItem {
    var escapedValue: String? {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove("/")

        return value?.addingPercentEncoding(withAllowedCharacters: characterSet)
    }
}

extension [URLQueryItem] {

    var asEscapedQueryString: String {
        self.sorted().map { "\($0.name)=\($0.escapedValue ?? "")" }.joined(separator: "&")
    }

    var escaped: [URLQueryItem] {
        self.map { URLQueryItem(name: $0.name, value: $0.escapedValue) }
    }

    func sorted() -> [URLQueryItem] {
        return sorted { lhs, rhs in
            lhs.name.lowercased() < rhs.name.lowercased()
        }
    }

    subscript(key: String) -> String? {
        return self.first { $0.name == key }?.value
    }

    static let empty: [URLQueryItem] = []
}
