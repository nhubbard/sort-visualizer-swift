import AlgorithmKit
import Foundation
import SortEngineKit

/// Trivially `Codable`, versionable, and validated at load time instead of regex-scraped from
/// JSDoc comments (§2.3).
struct AlgorithmManifest: Decodable {
    struct ComplexityBoundsPayload: Decodable {
        let best: String
        let average: String
        let worst: String
    }

    let id: String
    let displayName: String
    let category: AlgorithmCategory
    let stable: Bool
    /// `[min, max]` — decoded and validated into a `ClosedRange<Int>` by `makeMetadata()`.
    let sizeRange: [Int]
    let timeComplexity: ComplexityBoundsPayload
    let spaceComplexity: String
    let iconName: String
}

enum AlgorithmManifestError: Error, CustomStringConvertible {
    case invalidSizeRange([Int])

    var description: String {
        switch self {
        case let .invalidSizeRange(values):
            "sizeRange must be a two-element [min, max] array with min <= max, got \(values)"
        }
    }
}

extension AlgorithmManifest {
    func makeMetadata() throws -> AlgorithmMetadata {
        guard sizeRange.count == 2, sizeRange[0] <= sizeRange[1] else {
            throw AlgorithmManifestError.invalidSizeRange(sizeRange)
        }
        return AlgorithmMetadata(
            displayName: displayName,
            category: category,
            sizeRange: sizeRange[0]...sizeRange[1],
            stable: stable,
            timeComplexity: ComplexityBounds(
                best: timeComplexity.best,
                average: timeComplexity.average,
                worst: timeComplexity.worst
            ),
            spaceComplexity: spaceComplexity,
            iconName: iconName
        )
    }
}

/// The actual "drop-in" mechanism (§2.4): pairs each `*.manifest.json` with its sibling
/// `<id>.js`, decodes, wraps in `JSAlgorithmAdapter` — skipping and logging (never crashing) any
/// pair that fails manifest decoding, fails validation, or has a duplicate `id`.
public enum ScriptAlgorithmLoader {
    public static func loadScripts(from directory: URL) -> [any SortAlgorithm] {
        ScriptDiscovery.discover(
            in: directory,
            idOf: { (manifest: AlgorithmManifest) in manifest.id },
            build: { manifest, source in
                JSAlgorithmAdapter(
                    id: AlgorithmID(rawValue: manifest.id),
                    metadata: try manifest.makeMetadata(),
                    source: source
                )
            }
        )
    }
}
