// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SwiftEffector",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
        .library(
            name: "SwiftEffector",
            targets: ["SwiftEffector"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftEffector",
            dependencies: []),
        .testTarget(
            name: "SwiftEffectorTests",
            dependencies: ["SwiftEffector"])
    ])
