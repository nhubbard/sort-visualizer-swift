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
        let frameworkSettings = name.hasSuffix("Kit") ? baseSettings.merging(moduleVerifierSettings) { _, new in new } : baseSettings
        return [
            .target(
                name: name,
                destinations: destinations,
                product: .framework,
                bundleId: "com.nhubbard.Sort2.mobile.modules.\(name.lowercased())",
                deploymentTargets: deploymentTargets,
                sources: ["Modules/\(name)/Sources/**"],
                resources: resources,
                dependencies: dependencies,
                settings: .settings(base: frameworkSettings)
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
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
    ]

    /// Module Verifier settings (Xcode 14.3+) applied only to targets whose name ends in "Kit" —
    /// these are the modules meant to behave like standalone distributable frameworks (a stable
    /// public interface, buildable in isolation), unlike the `*Feature` modules, which are app
    /// screens that only ever get consumed by `Sort Symphony` itself.
    private static let moduleVerifierSettings: SettingsDictionary = [
        "ENABLE_MODULE_VERIFIER": "YES",
        "MODULE_VERIFIER_SUPPORTED_LANGUAGES": "objective-c objective-c++",
        "MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS": "gnu11 gnu++14",
    ]

    /// Discovers `App/Resources/AlgorithmDetails/<id>/` algorithm folders (each holding raw
    /// source alongside the finished `description.md`/`<lang>.md` content, see that directory's
    /// own README) and returns one Copy Files build phase per algorithm, shipping only that
    /// folder's `*.md` files under `AlgorithmDetails/<id>/` — raw source and pipeline files never
    /// reach the app bundle. One phase per algorithm is required, not one shared phase: a Copy
    /// Files phase applies a single destination subpath to every file it copies, so preserving
    /// the per-algorithm nesting `AlgorithmDetailContent` expects means each algorithm needs its
    /// own subpath. Matches this project's existing "no hardcoded lists" approach to registering
    /// content (see `ContentView.swift`'s algorithm-sidebar comment). `callerFilePath` defaults to
    /// the call site's own path (via `#filePath`), so the manifest-relative root is computed from
    /// wherever this is actually called rather than assumed from this file's own location.
    public static func algorithmDetailCopyFiles(callerFilePath: StaticString = #filePath) -> [CopyFilesAction] {
        let root = URL(fileURLWithPath: "\(callerFilePath)")
            .deletingLastPathComponent()
            .appendingPathComponent("App/Resources/AlgorithmDetails")
        let entries = (try? FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        )) ?? []
        // `template/` is the master template `scaffold.sh` copies from, not a real algorithm.
        let excluded: Set<String> = ["template"]
        let algorithmIDs = entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .map(\.lastPathComponent)
            .filter { !excluded.contains($0) }
            .sorted()
        return algorithmIDs.map { id in
            .resources(
                name: "AlgorithmDetails-\(id)",
                subpath: "AlgorithmDetails/\(id)",
                files: [.glob(pattern: .path("App/Resources/AlgorithmDetails/\(id)/*.md"))]
            )
        }
    }
}
