import AlgorithmKit
import Foundation
import SortEngineKit
import Testing
@testable import ScriptingKit

@MainActor
@Suite
struct ScriptShuffleLoaderTests {
    private func makeTempDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func validManifestJSON(id: String) -> String {
        """
        { "id": "\(id)", "displayName": "Test Shuffle" }
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
        try write("function shuffle(engine) {}", to: dir, filename: "broken.js")
        try write(validManifestJSON(id: "valid"), to: dir, filename: "valid.manifest.json")
        try write("function shuffle(engine) {}", to: dir, filename: "valid.js")

        let registry = ShuffleRegistry()
        registry.scriptLoader = { ScriptShuffleLoader.loadScripts(from: dir) }
        registry.discover()

        #expect(registry.shuffles.count == 1)
        #expect(registry.shuffles.first?.id.rawValue == "valid")
    }

    @Test
    func skipsDuplicateShuffleIDKeepingOnlyTheFirst() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        try write(validManifestJSON(id: "dup"), to: dir, filename: "dup-a.manifest.json")
        try write(validManifestJSON(id: "dup"), to: dir, filename: "dup-b.manifest.json")
        try write("function shuffle(engine) {}", to: dir, filename: "dup.js")

        let registry = ShuffleRegistry()
        registry.scriptLoader = { ScriptShuffleLoader.loadScripts(from: dir) }
        registry.discover()

        #expect(registry.shuffles.count == 1)
    }

    @Test
    func skipsManifestWithoutAMatchingScriptFile() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        try write(validManifestJSON(id: "orphan"), to: dir, filename: "orphan.manifest.json")

        let registry = ShuffleRegistry()
        registry.scriptLoader = { ScriptShuffleLoader.loadScripts(from: dir) }
        registry.discover()

        #expect(registry.shuffles.isEmpty)
    }
}
