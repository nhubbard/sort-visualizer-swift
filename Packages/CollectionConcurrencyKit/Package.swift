// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "CollectionConcurrencyKit",
  platforms: [.iOS(.v14), .macOS(.v12)],
  products: [
    .library(
      name: "CollectionConcurrencyKit",
      targets: ["CollectionConcurrencyKit"]
    )
  ],
  targets: [
    .target(name: "CollectionConcurrencyKit"),
    .testTarget(
      name: "CollectionConcurrencyKitTests",
      dependencies: ["CollectionConcurrencyKit"]
    )
  ]
)
