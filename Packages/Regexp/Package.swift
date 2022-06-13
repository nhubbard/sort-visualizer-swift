// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Regexp",
    products: [
        .library(name: "Regexp", targets: ["Regexp"]),
    ],
    targets: [
        .target(name: "Regexp", dependencies: []),
        .testTarget(name: "RegexpTests", dependencies: ["Regexp"]),
    ]
)
