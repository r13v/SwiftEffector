// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SwiftEffector",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
        .library(
            name: "SwiftEffector",
            targets: ["SwiftEffector"]),

        .library(
            name: "SwiftEffectorForms",
            targets: ["SwiftEffectorForms"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftEffector",
            dependencies: []),

        .testTarget(
            name: "EffectorTests",
            dependencies: ["SwiftEffector"]),

        .target(
            name: "SwiftEffectorForms",
            dependencies: ["SwiftEffector"]),

        .testTarget(
            name: "FormsTests",
            dependencies: ["SwiftEffector", "SwiftEffectorForms"]),

    ])
