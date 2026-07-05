import ProjectDescription

public enum Module {
    public static let deploymentTargets: DeploymentTargets = .iOS("26.0")
    public static let destinations: Destinations = [.iPad, .macCatalyst]

    /// A framework + its test target, sharing one bundle-ID/settings convention. This is the
    /// entire replacement for the current per-target `xcconfigs/*.xcconfig` files (§5.3).
    public static func framework(
        name: String,
        dependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil
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
                dependencies: [.target(name: name)],
                settings: .settings(base: baseSettings)
            ),
        ]
    }

    static let baseSettings: SettingsDictionary = [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
    ]
}
