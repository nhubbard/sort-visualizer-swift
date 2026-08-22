public struct VisualizerID: Hashable, Sendable, Codable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct VisualizerMetadata: Sendable, Codable, Equatable {
  public var displayName: String
  public var supportsAuxArrays: Bool
  public var iconName: String

  public init(displayName: String, supportsAuxArrays: Bool, iconName: String) {
    self.displayName = displayName
    self.supportsAuxArrays = supportsAuxArrays
    self.iconName = iconName
  }
}

/// Pluggable, but not scriptable (§2A.3) — a `Visualizer` is a pure, synchronous function from data
/// to data, `(VisualizationContext) -> [DrawCommand]`, which is already as swappable as a plugin
/// needs to be without paying for an interpreter, a per-frame watchdog, or bridge plumbing.
public protocol Visualizer: Sendable {
  var id: VisualizerID { get }
  var metadata: VisualizerMetadata { get }
  func draw(_ context: VisualizationContext) -> [DrawCommand]
}
