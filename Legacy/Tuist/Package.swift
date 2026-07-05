// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        // Customize the product types for specific package products
        // Default is .staticFramework
        productTypes: [
            "AudioKit": .framework,
            "AudioKitEX": .framework,
            "AudioKitUI": .framework,
            "SoundpipeAudioKit": .framework,
            "Controls": .framework
        ]
    )
#endif

let package = Package(
    name: "SortSymphony",
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/NetworkImage", from: "6.0.0"),
        .package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.6.5"),
        .package(url: "https://github.com/AudioKit/AudioKitEX.git", from: "5.6.2"),
        .package(url: "https://github.com/AudioKit/AudioKitUI.git", from: "0.3.7"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit.git", from: "5.6.1"),
        .package(url: "https://github.com/AudioKit/Controls.git", from: "1.1.4"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.6.0"),
        .package(url: "https://github.com/gonzalezreal/MarkdownUI", from: "2.4.1"),
        .package(url: "https://github.com/mgriebling/SwiftMath.git", from: "1.7.1"),
        .package(url: "https://github.com/devxoul/Then", from: "3.0.0"),
        .package(url: "https://github.com/nhubbard/CollectionConcurrencyKit", from: "2.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.1"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0")
    ]
)
