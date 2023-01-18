import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct HttpHeaders {
    private let headers: [String: String]

    enum HeaderType: String {
        case acceptRanges           = "Accept-Ranges"
        case authorization          = "Authorization"
        case contentLength          = "Content-Length"
        case contentRange           = "Content-Range"
        case contentType            = "Content-Type"
        case eTag                   = "Etag"
        case host                   = "Host"
        case lastModified           = "Last-Modified"
        case range                  = "Range"

        // Custom Headers
        case xAmzDate               = "x-amz-date"
        case xAmxContentSha256      = "x-amz-content-sha256"
    }

    init(_ headers: [HeaderType: String] = [:]) {
        self.headers = headers.reduce(into: [String: String](), { $0[$1.key.rawValue] = $1.value })
    }

    init(from response: HTTPURLResponse) {
        let headers = response.allHeaderFields.map {
            ($0.key.description, response.value(forHTTPHeaderField: $0.key.description))
        }.reduce(into: [String: String]()) { $0[$1.0] = $1.1 }

        self.init(headers: headers)
    }

    private init(headers: [String: String]) {
        self.headers = headers
    }

    func adding(_ headers: [String: String]) -> HttpHeaders {
        var tmp = self.headers
        for header in headers {
            tmp[header.key] = header.value
        }
        return HttpHeaders(headers: tmp)
    }

    func adding(_ headers: [HeaderType: String]) -> HttpHeaders {
        var tmp = self.headers
        for header in headers {
            tmp[header.key.rawValue] = header.value
        }
        return HttpHeaders(headers: tmp)
    }

    func adding(_ key: HeaderType, value: String) -> HttpHeaders {
        var tmp = self.headers
        tmp[key.rawValue] = value
        return HttpHeaders(headers: tmp)
    }

    func removing(key: String) -> HttpHeaders {
        var tmp = self.headers
        tmp.removeValue(forKey: key)
        return HttpHeaders(headers: tmp)
    }

    var canonicalized: String {
        headers
            .map {
                let key = $0.key.lowercased()
                let value = $0.value.trimmingCharacters(in: .whitespacesAndNewlines)

                return "\(key):\(value)"
            }
            .sorted()
            .joined(separator: "\n")
    }

    var signed: String {
        headers
            .map { $0.key.lowercased() }
            .sorted()
            .joined(separator: ";")
    }

    var toHttpHeaderFields: [String: String] {
        self.headers
    }

    subscript(key: HeaderType) -> String? {
        self.headers.first { $0.key == key.rawValue }?.value
    }
}

extension HTTPURLResponse {
    func value(forHTTPHeaderField header: HttpHeaders.HeaderType) -> String? {
        self.value(forHTTPHeaderField: header.rawValue)
    }
}
