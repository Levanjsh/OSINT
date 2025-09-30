// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OSINTScout",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "OSINTScout",
            targets: ["OSINTScout"]
        )
    ],
    targets: [
        .target(
            name: "OSINTScout",
            path: "OSINTScout"
        ),
        .testTarget(
            name: "OSINTScoutTests",
            dependencies: ["OSINTScout"],
            path: "Tests"
        )
    ]
)
