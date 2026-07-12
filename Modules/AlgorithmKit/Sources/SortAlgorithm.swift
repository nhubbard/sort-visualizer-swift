import SortEngineKit

/// Native and scripted algorithms produce the exact same thing — a `Tape` — through this exact
/// primitive surface. From the rest of the app's point of view there is no difference between a
/// native `SortAlgorithm` conformance and a JS-scripted one (§2.1).
public protocol SortAlgorithm: Sendable {
    var id: AlgorithmID { get }
    var metadata: AlgorithmMetadata { get }
    func record(into engine: inout RecordingEngine)
}

public struct AlgorithmID: Hashable, Sendable, Codable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
