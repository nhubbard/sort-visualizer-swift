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
        // Extra dependencies for the "<name>Tests" target only, beyond the framework itself —
        // Swift module visibility isn't transitive across target boundaries, so a test that needs
        // to `import` one of the framework's own dependencies directly (not just through the
        // framework's public API) needs it listed here too.
        testDependencies: [TargetDependency] = [],
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
                dependencies: [.target(name: name)] + testDependencies,
                settings: .settings(base: baseSettings)
            )
        ]
    }

    /// For non-`Modules/`-resident product targets whose `product` `Module.framework` can't
    /// express (it hardcodes `.framework`) — first user: the AUv3 extension target
    /// (`AUDIO_UNIT_PLAN.md` Phase 3), with a second (macOS AUv3 packaging, Phase 4) already a
    /// known near-term need, which is why this is a small reusable helper rather than one
    /// hand-rolled `Target.target(...)` call. Sources live under `App/<name>/Sources/**`,
    /// mirroring `App/UITests/` as the existing precedent for a non-`Module.framework` product
    /// target living alongside the app rather than under `Modules/`.
    public static func appExtension(
        name: String,
        destinations: Destinations,
        dependencies: [TargetDependency] = [],
        infoPlist: InfoPlist,
        entitlements: Entitlements? = nil,
        extraSettings: SettingsDictionary = [:]
    ) -> Target {
        .target(
            name: name,
            destinations: destinations,
            product: .appExtension,
            bundleId: "com.nhubbard.Sort2.mobile.\(name.lowercased())",
            deploymentTargets: deploymentTargets,
            infoPlist: infoPlist,
            sources: ["App/\(name)/Sources/**"],
            entitlements: entitlements,
            dependencies: dependencies,
            settings: .settings(base: baseSettings.merging(extraSettings) { _, new in new })
        )
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
}
