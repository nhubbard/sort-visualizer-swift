import AlgorithmKit
import Foundation

/// Much smaller than `AlgorithmManifest` — a shuffle has no complexity bounds, size range, or
/// confirmation warning to describe, just an id and a display name.
struct ShuffleManifest: Decodable {
    let id: String
    let displayName: String
}

extension ShuffleManifest {
    func makeMetadata() -> ShuffleMetadata {
        ShuffleMetadata(displayName: displayName)
    }
}

/// Same drop-in mechanism as `ScriptAlgorithmLoader`, for shuffles (§2A.4).
public enum ScriptShuffleLoader {
    public static func loadScripts(from directory: URL) -> [any ShuffleAlgorithm] {
        ScriptDiscovery.discover(
            in: directory,
            idOf: { (manifest: ShuffleManifest) in manifest.id },
            build: { manifest, source in
                JSShuffleAdapter(
                    id: ShuffleID(rawValue: manifest.id),
                    metadata: manifest.makeMetadata(),
                    source: source
                )
            }
        )
    }
}
