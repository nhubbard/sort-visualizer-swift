import AlgorithmKit
import Foundation
import SortEngineKit
import Testing
@testable import ScriptingKit

/// Anchor for locating the test bundle — `ScriptingKitTests` references
/// `App/Resources/Algorithms`/`Shuffles` directly (no duplication) via `testResources` in
/// `Project.swift`, so this exercises the exact same `ScriptAlgorithmLoader`/`ScriptShuffleLoader`
/// code path the real app uses against the exact files it ships, not a hand-picked sample.
private final class BundleAnchor {}

private struct MissingBundledResource: Error, CustomStringConvertible {
    let name: String
    var description: String {
        "\(name) folder reference missing from ScriptingKitTests bundle — check Project.swift's testResources"
    }
}

private func bundledDirectory(named name: String) throws -> URL {
    guard let url = Bundle(for: BundleAnchor.self).url(forResource: name, withExtension: nil) else {
        throw MissingBundledResource(name: name)
    }
    return url
}

/// The number of `*.manifest.json` files actually on disk — the loader is expected to load
/// exactly this many, never fewer. Comparing against `!isEmpty` alone previously let a real bug
/// (`bogosort.manifest.json`'s `confirmationWarning` field failing to decode, silently skipped by
/// `ScriptDiscovery`) hide for an entire batch of algorithms; this catches any future silent skip
/// the same way would cause.
private func manifestFileCount(in directory: URL) throws -> Int {
    try FileManager.default
        .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        .filter { $0.lastPathComponent.hasSuffix(".manifest.json") }
        .count
}

@Suite
struct BundledContentCorrectnessTests {
    @Test
    func everyBundledAlgorithmSortsRandomInputsCorrectly() throws {
        let directory = try bundledDirectory(named: "Algorithms")
        let algorithms = ScriptAlgorithmLoader.loadScripts(from: directory)
        let expectedCount = try manifestFileCount(in: directory)
        #expect(
            algorithms.count == expectedCount,
            "expected every *.manifest.json in Algorithms/ to load — one or more silently failed decoding"
        )

        for algorithm in algorithms {
            // Each algorithm's own sizeRange lower bound — always in its comfortable range, and
            // small enough that even BogoSort-like algorithms stay fast.
            let size = algorithm.metadata.sizeRange.lowerBound

            for attempt in 0..<3 {
                let input = (0..<size).map { _ in Int.random(in: 0...1000) }
                var engine = RecordingEngine(values: input)
                algorithm.record(into: &engine)

                #expect(
                    engine.values == input.sorted(),
                    """
                    \(algorithm.id.rawValue) failed to sort attempt \(attempt) of size \(size): \
                    \(input) -> \(engine.values)
                    """
                )
            }
        }
    }

    @Test
    func everyBundledShuffleRunsWithoutCrashingAndPreservesArrayLength() throws {
        let directory = try bundledDirectory(named: "Shuffles")
        let shuffles = ScriptShuffleLoader.loadScripts(from: directory)
        let expectedCount = try manifestFileCount(in: directory)
        #expect(
            shuffles.count == expectedCount,
            "expected every *.manifest.json in Shuffles/ to load — one or more silently failed decoding"
        )

        let size = 24
        let identity = Array(1...size)

        for shuffle in shuffles {
            var engine = RecordingEngine(values: identity)
            shuffle.record(into: &engine)

            // A shuffle isn't a sort, and isn't even guaranteed to *permute* — some (e.g. v1's
            // shuffledcubic/shuffledquintic) deliberately remap values through a curve via
            // setValue, matching ArrayV's own "shuffle == just another instrumented algorithm"
            // model (§2A.4). The one universal invariant is that the array's length is unchanged.
            #expect(engine.values.count == identity.count, "\(shuffle.id.rawValue) changed the array's length")
        }
    }
}
