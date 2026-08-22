// swift-tools-version: 6.0
import PackageDescription

/// Makes this same `Sources/`/`Tests/` tree a standalone, independently buildable/testable Swift
/// package (`cd Modules/ZstdKit && swift build && swift test`) — purely additive, coexisting with
/// Tuist's own `Module.framework(name: "ZstdKit", ...)` glob-based consumption in the app's
/// `Project.swift` (left completely untouched; that mechanism doesn't read this file at all, only
/// `Tuist/Package.swift` is Tuist's own dependency manifest). Platform minimums here are
/// deliberately broad — well below what anything in this module actually needs (`SIMD16<UInt8>`
/// has shipped since Swift 5.0) — since a package meant for *other* projects shouldn't inherit
/// this app's own iOS-18-specific floor. See Documentation/docs/reference/compression.md.
let package = Package(
  name: "ZstdKit",
  platforms: [
    .iOS(.v13), .macOS(.v10_15), .macCatalyst(.v13), .tvOS(.v13), .watchOS(.v6)
  ],
  products: [
    .library(name: "ZstdKit", targets: ["ZstdKit"])
  ],
  targets: [
    .target(name: "ZstdKit", path: "Sources"),
    .testTarget(
      name: "ZstdKitTests", dependencies: ["ZstdKit"], path: "Tests",
      resources: [.copy("Fixtures")]
    )
  ]
)
