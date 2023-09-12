import Foundation

@available(macOS 10.15.4, *)
struct CompleteMultipartUploadRequestBodyBuilder {

    struct EncodingOptions: OptionSet {
        let rawValue: Int

        static let prettyPrinted    = EncodingOptions(rawValue: 1 << 0)
        static let escaped          = EncodingOptions(rawValue: 1 << 1)
    }

    private let document: XMLDocument
    private let header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"

    init() {
        let rootElement = XMLElement(name: "CompleteMultipartUpload")
        rootElement.setAttributesWith(["xmlns": "http://s3.amazonaws.com/doc/2006-03-01/"])

        self.document = XMLDocument(rootElement: rootElement)
    }

    init(document: XMLDocument) {
        self.document = document
    }

    @discardableResult
    func addPart(_ part: MultipartUploadOperation.AWSUploadedPart) -> Self {
        let partNode = XMLElement(name: "Part")
        partNode.addChild(XMLElement(name: "PartNumber", stringValue: String(part.number)))
        partNode.addChild(XMLElement(name: "ETag", stringValue: part.eTag))
        document.rootElement()?.addChild(partNode)

        return self
    }

    @discardableResult
    func addParts(_ parts: [MultipartUploadOperation.AWSUploadedPart]) -> Self {
        for part in parts {
            addPart(part)
        }

        return self
    }

    func build(options: EncodingOptions = []) -> String {
        let xmlOptions = options.contains(.prettyPrinted) ? XMLElement.Options.nodePrettyPrint : []
        let originalString = document.xmlString(options: xmlOptions).trimmingCharacters(in: .whitespacesAndNewlines)

        guard options.contains(.escaped) else {
            return originalString.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return originalString
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func build(options: EncodingOptions = []) -> Data {
        let xmlOptions = options.contains(.prettyPrinted) ? XMLElement.Options.nodePrettyPrint : []
        return Data(header.utf8) + document.xmlData(options: xmlOptions)
    }
}

