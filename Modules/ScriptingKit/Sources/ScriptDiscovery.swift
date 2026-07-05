import Foundation

/// The actual "drop-in" mechanism (§2.4), generalized over `AlgorithmManifest`/`ShuffleManifest`:
/// pairs each `*.manifest.json` with its sibling `<id>.js`, decodes, and hands both to `build` —
/// skipping and logging (never crashing) any pair that fails manifest decoding, fails validation
/// (a `build` that throws), or has a duplicate `id`.
enum ScriptDiscovery {
    static func discover<Manifest: Decodable, Result>(
        in directory: URL,
        idOf: (Manifest) -> String,
        build: (Manifest, String) throws -> Result
    ) -> [Result] {
        let manifestURLs = ((try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? [])
        .filter { $0.lastPathComponent.hasSuffix(".manifest.json") }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var results: [Result] = []
        var seenIDs: Set<String> = []

        for manifestURL in manifestURLs {
            do {
                let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: manifestURL))
                let id = idOf(manifest)

                guard !seenIDs.contains(id) else {
                    logSkip("duplicate id \"\(id)\"", manifestURL: manifestURL)
                    continue
                }

                let scriptURL = directory.appendingPathComponent(id).appendingPathExtension("js")
                let source = try String(contentsOf: scriptURL, encoding: .utf8)
                let result = try build(manifest, source)

                seenIDs.insert(id)
                results.append(result)
            } catch {
                logSkip("\(error)", manifestURL: manifestURL)
            }
        }
        return results
    }

    private static func logSkip(_ reason: String, manifestURL: URL) {
        #if DEBUG
        print("[ScriptDiscovery] Skipping \(manifestURL.lastPathComponent): \(reason)")
        #endif
    }
}
