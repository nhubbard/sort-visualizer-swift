/// Marker IDs, borrowed directly from ArrayV's `Highlights`: a marker stays "on" an index until
/// something explicitly clears it, rather than being scoped to a single operation. What a
/// marker *looks like* is entirely a `Visualizer`'s decision — this engine only ever tracks bare
/// integer IDs, never colors or shapes.
public enum Marker {
  /// Auto-applied by `RecordingEngine.compare`/`.swap`, and auto-*retracted* from whichever pair
  /// of indices previously held them the moment a new pair is touched — these two exist to mean
  /// "the operation happening right now," not "every index ever compared this run."
  public static let primary = 1
  public static let secondary = 2
  /// Algorithm-managed, e.g. held across a whole partition pass.
  public static let pivot = 3
  public static let write = 4
  public static func bucket(_ n: Int) -> Int { 100 + n }
}
