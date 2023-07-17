// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Effector",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        .library(
            name: "Effector",
            targets: ["Effector"]),

        .library(
            name: "EffectorForms",
            targets: ["EffectorForms"]),
    ],
    targets: [
        .target(
            name: "Effector",
            dependencies: [],
            path: "Effector"),

        .testTarget(
            name: "EffectorTests",
            dependencies: ["Effector"]),

        .target(
            name: "EffectorForms",
            dependencies: ["Effector"],
            path: "EffectorForms"),

        .testTarget(
            name: "EffectorFormsTests",
            dependencies: ["Effector", "EffectorForms"]
        ),
    ])
