import Foundation
import ProjectDescription

public enum Module {
    public static let deploymentTargets: DeploymentTargets = .iOS("26.0")
    public static let destinations: Destinations = [.iPad, .macCatalyst]

    /// A framework + its test target, sharing one bundle-ID/settings convention. This is the
    /// entire replacement for the current per-target `xcconfigs/*.xcconfig` files (§5.3).
    public static func framework(
        name: String,
        dependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil,
        testResources: ResourceFileElements? = nil
    ) -> [Target] {
        [
            .target(
                name: name,
                destinations: destinations,
                product: .framework,
                bundleId: "com.nhubbard.Sort2.mobile.modules.\(name.lowercased())",
                deploymentTargets: deploymentTargets,
                sources: ["Modules/\(name)/Sources/**"],
                resources: resources,
                dependencies: dependencies,
                settings: .settings(base: baseSettings)
            ),
            .target(
                name: "\(name)Tests",
                destinations: destinations,
                product: .unitTests,
                bundleId: "com.nhubbard.Sort2.mobile.modules.\(name.lowercased()).tests",
                deploymentTargets: deploymentTargets,
                sources: ["Modules/\(name)/Tests/**"],
                resources: testResources,
                dependencies: [.target(name: name)],
                settings: .settings(base: baseSettings)
            ),
        ]
    }

    public static let baseSettings: SettingsDictionary = [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
    ]

    /// Discovers shipped `App/Resources/AlgorithmDetails/<id>/` output folders, skipping the
    /// sibling `<name>.bundle/` authoring bundles (raw source + the Pygments highlighting
    /// pipeline, see that directory's own README) — a plain top-level `.folderReference` would
    /// ship those too, so each shipped folder is named individually here instead. Matches this
    /// project's existing "no hardcoded lists" approach to registering content (see
    /// `ContentView.swift`'s algorithm-sidebar comment). `callerFilePath` defaults to the call
    /// site's own path (via `#filePath`), so the manifest-relative root is computed from wherever
    /// this is actually called rather than assumed from this file's own location.
    public static func algorithmDetailCopyFiles(callerFilePath: StaticString = #filePath) -> [CopyFileElement] {
        let root = URL(fileURLWithPath: "\(callerFilePath)")
            .deletingLastPathComponent()
            .appendingPathComponent("App/Resources/AlgorithmDetails")
        let entries = (try? FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        )) ?? []
        let shippedNames = entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .map(\.lastPathComponent)
            .filter { !$0.hasSuffix(".bundle") }
            .sorted()
        return shippedNames.map { .folderReference(path: .path("App/Resources/AlgorithmDetails/\($0)")) }
    }
}
