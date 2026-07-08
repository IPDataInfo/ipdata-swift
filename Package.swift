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
            path: "Tests/IPDataTests",
            swiftSettings: [
                // Command-Line-Tools-only macOS installs (no full Xcode) keep
                // the Swift Testing framework outside the default search
                // path, and lack the Testing+Foundation cross-import overlay
                // module entirely. Both flags are no-ops (warning only) on
                // any machine where the standard paths already resolve.
                .unsafeFlags(
                    ["-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                     "-Xfrontend", "-disable-cross-import-overlays"],
                    .when(platforms: [.macOS])
                ),
            ],
            linkerSettings: [
                .unsafeFlags(
                    ["-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                     "-Xlinker", "-rpath",
                     "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"],
                    .when(platforms: [.macOS])
                ),
            ]
        ),
    ]
)
