import AlgorithmKit
import Foundation
import SortEngineKit
import Testing
@testable import ScriptingKit

@MainActor
@Suite
struct ScriptAlgorithmLoaderTests {
    private func makeTempDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func validManifestJSON(id: String) -> String {
        """
        {
            "id": "\(id)",
            "displayName": "Test Algorithm",
            "category": "exchange",
            "stable": true,
            "sizeRange": [4, 64],
            "timeComplexity": { "best": "O(n)", "average": "O(n^2)", "worst": "O(n^2)" },
            "spaceComplexity": "O(1)",
            "iconName": "test"
        }
        """
    }

    private func write(_ contents: String, to directory: URL, filename: String) throws {
        try contents.write(to: directory.appendingPathComponent(filename), atomically: true, encoding: .utf8)
    }

    @Test
    func skipsManifestMissingRequiredFieldsButKeepsValidOnes() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        try write(#"{"id": "broken"}"#, to: dir, filename: "broken.manifest.json")
        try write("function sort(engine) {}", to: dir, filename: "broken.js")
        try write(validManifestJSON(id: "valid"), to: dir, filename: "valid.manifest.json")
        try write("function sort(engine) {}", to: dir, filename: "valid.js")

        let registry = AlgorithmRegistry()
        registry.scriptLoader = { ScriptAlgorithmLoader.loadScripts(from: dir) }
        registry.discover()

        #expect(registry.algorithms.count == 1)
        #expect(registry.algorithms.first?.id.rawValue == "valid")
    }

    @Test
    func skipsManifestWithInvalidSizeRangeButKeepsValidOnes() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let badRangeJSON = """
        {
            "id": "badrange", "displayName": "Bad Range", "category": "exchange", "stable": false,
            "sizeRange": [64, 4],
            "timeComplexity": { "best": "O(n)", "average": "O(n)", "worst": "O(n)" },
            "spaceComplexity": "O(1)", "iconName": "test"
        }
        """
        try write(badRangeJSON, to: dir, filename: "badrange.manifest.json")
        try write("function sort(engine) {}", to: dir, filename: "badrange.js")
        try write(validManifestJSON(id: "valid"), to: dir, filename: "valid.manifest.json")
        try write("function sort(engine) {}", to: dir, filename: "valid.js")

        let registry = AlgorithmRegistry()
        registry.scriptLoader = { ScriptAlgorithmLoader.loadScripts(from: dir) }
        registry.discover()

        #expect(registry.algorithms.count == 1)
        #expect(registry.algorithms.first?.id.rawValue == "valid")
    }

    @Test
    func skipsDuplicateAlgorithmIDKeepingOnlyTheFirst() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        try write(validManifestJSON(id: "dup"), to: dir, filename: "dup-a.manifest.json")
        try write(validManifestJSON(id: "dup"), to: dir, filename: "dup-b.manifest.json")
        try write("function sort(engine) {}", to: dir, filename: "dup.js")

        let registry = AlgorithmRegistry()
        registry.scriptLoader = { ScriptAlgorithmLoader.loadScripts(from: dir) }
        registry.discover()

        #expect(registry.algorithms.count == 1)
    }

    @Test
    func skipsManifestWithoutAMatchingScriptFile() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        try write(validManifestJSON(id: "orphan"), to: dir, filename: "orphan.manifest.json")
        // no orphan.js written

        let registry = AlgorithmRegistry()
        registry.scriptLoader = { ScriptAlgorithmLoader.loadScripts(from: dir) }
        registry.discover()

        #expect(registry.algorithms.isEmpty)
    }

    @Test
    func discoverCombinesBuiltInsAndScriptedAlgorithms() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        try write(validManifestJSON(id: "scripted"), to: dir, filename: "scripted.manifest.json")
        try write("function sort(engine) {}", to: dir, filename: "scripted.js")

        let registry = AlgorithmRegistry()
        registry.builtIns = [FakeNativeAlgorithm()]
        registry.scriptLoader = { ScriptAlgorithmLoader.loadScripts(from: dir) }
        registry.discover()

        #expect(registry.algorithms.map(\.id.rawValue) == ["native", "scripted"])
    }
}

private struct FakeNativeAlgorithm: SortAlgorithm {
    let id = AlgorithmID(rawValue: "native")
    let metadata = AlgorithmMetadata(
        displayName: "Fake",
        category: .exchange,
        sizeRange: 1...10,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(1)", average: "O(1)", worst: "O(1)"),
        spaceComplexity: "O(1)",
        iconName: "fake"
    )

    func record(into engine: inout RecordingEngine) {}
}
