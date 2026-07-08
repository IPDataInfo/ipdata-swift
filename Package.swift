// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "IPData",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        .library(name: "IPData", targets: ["IPData"]),
    ],
    targets: [
        .target(
            name: "IPData",
            dependencies: [],
            path: "Sources/IPData"
        ),
        .executableTarget(
            name: "ipdata-example",
            dependencies: ["IPData"],
            path: "Sources/ipdata-example"
        ),
        .testTarget(
            name: "IPDataTests",
            dependencies: ["IPData"],
            path: "Tests/IPDataTests"
        ),
    ]
)
