import Foundation
import ProjectDescription

public enum Module {
    // Building against the iOS 26 SDK (for RunControlBar's Liquid Glass `glassEffect`, gated
    // behind `#available` there) doesn't require the deployment target to match it — this stays
    // as low as the rest of the app's API usage allows.
    public static let deploymentTargets: DeploymentTargets = .iOS("18.0")
    public static let destinations: Destinations = [.iPad, .macCatalyst]

    /// A framework + its test target, sharing one bundle-ID/settings convention — replaces the
    /// per-target `xcconfigs/*.xcconfig` files.
    ///
    /// The test target is only included when `Modules/<name>/Tests` has at least one `.swift`
    /// file — a test target with zero source files still builds but produces no executable, so
    /// `xctest` fails to load its bundle at *run* time, not at generation time. Skipping the
    /// target entirely when there's nothing to test avoids requiring every module to keep a dummy
    /// test file around just to pass generation. `callerFilePath` defaults to the call site's own
    /// path (via `#filePath`) so the manifest-relative root is computed correctly regardless of
    /// where this helper is called from.
    public static func framework(
        name: String,
        dependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil,
        testResources: ResourceFileElements? = nil,
        callerFilePath: StaticString = #filePath
    ) -> [Target] {
        let frameworkSettings = name.hasSuffix("Kit") ? baseSettings.merging(moduleVerifierSettings) { _, new in new } : baseSettings
        let framework = Target.target(
            name: name,
            destinations: destinations,
            product: .framework,
            bundleId: "com.nhubbard.Sort2.mobile.modules.\(name.lowercased())",
            deploymentTargets: deploymentTargets,
            sources: ["Modules/\(name)/Sources/**"],
            resources: resources,
            dependencies: dependencies,
            settings: .settings(base: frameworkSettings)
        )
        guard hasSwiftTestSources(forModule: name, callerFilePath: callerFilePath) else {
            return [framework]
        }
        return [
            framework,
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
            )
        ]
    }

    private static func hasSwiftTestSources(forModule name: String, callerFilePath: StaticString) -> Bool {
        let testsDirectory = URL(fileURLWithPath: "\(callerFilePath)")
            .deletingLastPathComponent()
            .appendingPathComponent("Modules/\(name)/Tests")
        guard let enumerator = FileManager.default.enumerator(
            at: testsDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        ) else { return false }
        return enumerator.contains { ($0 as? URL)?.pathExtension == "swift" }
    }

    public static let baseSettings: SettingsDictionary = [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "STRING_CATALOG_GENERATE_SYMBOLS": "YES"
    ]

    /// Module Verifier settings (Xcode 14.3+) applied only to targets whose name ends in "Kit" —
    /// these are the modules meant to behave like standalone distributable frameworks (a stable
    /// public interface, buildable in isolation), unlike the `*Feature` modules, which are app
    /// screens that only ever get consumed by `Sort Symphony` itself.
    private static let moduleVerifierSettings: SettingsDictionary = [
        "ENABLE_MODULE_VERIFIER": "YES",
        "MODULE_VERIFIER_SUPPORTED_LANGUAGES": "objective-c objective-c++",
        "MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS": "gnu11 gnu++14"
    ]

    /// Discovers `App/Resources/AlgorithmDetails/<id>/` algorithm folders and returns one Copy
    /// Files build phase per algorithm, shipping only that folder's `*.md` files under
    /// `AlgorithmDetails/<id>/` — raw source and pipeline files never reach the app bundle. One
    /// phase per algorithm is required, not one shared phase: a Copy Files phase applies a single
    /// destination subpath to every file it copies, so preserving the per-algorithm nesting
    /// `AlgorithmDetailContent` expects means each algorithm needs its own subpath.
    /// `callerFilePath` defaults to the call site's own path (via `#filePath`) so the
    /// manifest-relative root is computed correctly regardless of where this is called from.
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
