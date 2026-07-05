import AlgorithmKit
import Foundation
import SortEngineKit

/// Trivially `Codable`, versionable, and validated at load time instead of regex-scraped from
/// JSDoc comments (§2.3). Plain-`String` `confirmationWarning` fields, not `AlgorithmWarning`
/// itself — `LocalizedStringResource`'s own `Codable` conformance round-trips its *internal*
/// representation, not a bare author-facing string, so manifests describe warnings as plain
/// strings and `makeMetadata()` below does the conversion.
struct AlgorithmManifest: Decodable {
    struct ComplexityBoundsPayload: Decodable {
        let best: String
        let average: String
        let worst: String
    }

    struct ConfirmationWarningPayload: Decodable {
        let title: String
        let message: String
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
    let confirmationWarning: ConfirmationWarningPayload?
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
            confirmationWarning: confirmationWarning.map {
                AlgorithmWarning(
                    title: LocalizedStringResource(stringLiteral: $0.title),
                    message: LocalizedStringResource(stringLiteral: $0.message)
                )
            },
            iconName: iconName
        )
    }
}

/// The actual "drop-in" mechanism (§2.4): pairs each `*.manifest.json` with its sibling
/// `<id>.js`, decodes, wraps in `JSAlgorithmAdapter` — skipping and logging (never crashing) any
/// pair that fails manifest decoding, fails validation, or has a duplicate `id`.
public enum ScriptAlgorithmLoader {
    public static func loadScripts(from directory: URL) -> [any SortAlgorithm] {
        let manifestURLs = ((try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? [])
        .filter { $0.lastPathComponent.hasSuffix(".manifest.json") }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var algorithms: [any SortAlgorithm] = []
        var seenIDs: Set<String> = []

        for manifestURL in manifestURLs {
            do {
                let manifest = try JSONDecoder().decode(AlgorithmManifest.self, from: Data(contentsOf: manifestURL))

                guard !seenIDs.contains(manifest.id) else {
                    logSkip("duplicate id \"\(manifest.id)\"", manifestURL: manifestURL)
                    continue
                }

                let metadata = try manifest.makeMetadata()
                let scriptURL = directory
                    .appendingPathComponent(manifest.id)
                    .appendingPathExtension("js")
                let source = try String(contentsOf: scriptURL, encoding: .utf8)

                seenIDs.insert(manifest.id)
                algorithms.append(JSAlgorithmAdapter(
                    id: AlgorithmID(rawValue: manifest.id),
                    metadata: metadata,
                    source: source
                ))
            } catch {
                logSkip("\(error)", manifestURL: manifestURL)
            }
        }
        return algorithms
    }

    private static func logSkip(_ reason: String, manifestURL: URL) {
        #if DEBUG
        print("[ScriptAlgorithmLoader] Skipping \(manifestURL.lastPathComponent): \(reason)")
        #endif
    }
}
