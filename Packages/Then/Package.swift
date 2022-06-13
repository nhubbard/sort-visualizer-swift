// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "Then",
  platforms: [
    .macOS(.v12), .iOS(.v15)
  ],
  products: [
    .library(name: "Then", targets: ["Then"]),
  ],
  targets: [
    .target(name: "Then"),
    .testTarget(name: "ThenTests", dependencies: ["Then"])
  ]
)
