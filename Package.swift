// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MiAuth",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "MiAuth",
            targets: ["MiAuth"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MiAuth",
            dependencies: []),
        .testTarget(
            name: "MiAuthTests",
            dependencies: ["MiAuth"]),
    ]
)
