// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tinys3",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v11),
        .tvOS(.v11),
        .watchOS(.v4),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "tinys3",
            targets: ["tinys3"]
        ),
        .executable(name: "cli", targets: [
            "cli",
        ])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.2.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "tinys3",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
        .executableTarget(
            name: "cli",
            dependencies: [
                "tinys3",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "tinys3Tests",
            dependencies: [
                "tinys3",
                .product(name: "Crypto", package: "swift-crypto"),
            ],
            resources: [
                .copy("resources/aws-credentials-file-multiple.txt"),
                .copy("resources/aws-credentials-file-no-region.txt"),
                .copy("resources/aws-credentials-file-single.txt"),
                .copy("resources/CompleteMultipartUploadDocument.txt"),
                .copy("resources/CompleteMultipartUploadRequest.txt"),
                .copy("resources/CreateMultipartUpload.xml"),
                .copy("resources/EmptyXML.xml"),
                .copy("resources/ErrorDataRedirect.xml"),
                .copy("resources/EscapedCompleteMultipartBody.xml"),
                .copy("resources/ListBucketData.xml"),
                .copy("resources/ListBucketDataEmpty.xml"),
                .copy("resources/ListBucketDataInvalid.xml"),
            ]
        ),
        .testTarget(
            name: "e2eTests",
            dependencies: [
                "tinys3"
            ],
            exclude: [
                "sample-data"
            ]
        )
    ]
)
