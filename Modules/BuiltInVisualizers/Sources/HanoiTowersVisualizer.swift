import SortEngineKit
import VisualizationKit

/// Not a literal replay of `HanoiSort`'s own puzzle-solving — this is a dramatized layout usable
/// with any algorithm: the array is split into a number of visual towers by CURRENT INDEX (not
/// value), so as any algorithm's `swap`/`setValue` operations move elements around the array, they
/// visibly travel between towers. This plain conformance only describes the resting-state layout
/// (one block per index, no animation); the actual lift-obstacles/carry/place/restore choreography
/// on top of it is `MetalHanoiTowersRenderer`'s job (`Modules/SortFeature/Sources/`), driven by
/// `SortOperation`s this type never sees — same split every other visualizer/Metal-renderer pair
/// already has (§2A).
public struct HanoiTowersVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "hanoitowers")
  public let metadata = VisualizerMetadata(
    displayName: "Hanoi Towers",
    supportsAuxArrays: false,
    iconName: "square.stack.3d.up.fill"
  )

  private static let primaryColor = RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1)
  private static let secondaryColor = RGBAColor(red: 0.38, green: 0.58, blue: 0.95, alpha: 1)

  public init() {}

  /// Towers scale gently with array size — few enough that each tower holds a visually
  /// legible stack, many enough that a large array doesn't pile hundreds of blocks into 3 towers.
  public static func towerCount(for count: Int) -> Int {
    guard count > 0 else { return 1 }
    return max(3, min(8, Int(Double(count).squareRoot().rounded())))
  }

  /// Index assignment is monotonic in `index` (tower boundaries only ever move forward as
  /// `index` increases), so every tower's member indices form one contiguous run — `depth(_:)`
  /// is just how far `index` sits into its own run.
  public static func tower(forIndex index: Int, count: Int, towerCount: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(towerCount - 1, index * towerCount / count)
  }

  public func draw(_ context: VisualizationContext) -> [DrawCommand] {
    guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0
    else {
      return []
    }

    let count = context.values.count
    let towers = Self.towerCount(for: count)
    let towerWidth = context.canvasSize.width / Double(towers)
    let maxDepth = (count + towers - 1) / towers
    let blockHeight = context.canvasSize.height / Double(maxDepth)
    let spanLength = Double(context.valueRange.upperBound - context.valueRange.lowerBound)

    var depthInTower = [Int](repeating: 0, count: towers)

    return context.values.enumerated().map { index, value in
      let tower = Self.tower(forIndex: index, count: count, towerCount: towers)
      let depth = depthInTower[tower]
      depthInTower[tower] += 1

      let normalized =
        spanLength > 0
        ? Double(value - context.valueRange.lowerBound) / spanLength
        : 1.0
      return .rect(
        x: Double(tower) * towerWidth + towerWidth * 0.1,
        y: context.canvasSize.height - Double(depth + 1) * blockHeight,
        width: towerWidth * 0.8,
        height: blockHeight * 0.9,
        color: color(forIndex: index, normalized: normalized, in: context)
      )
    }
  }

  private func color(forIndex index: Int, normalized: Double, in context: VisualizationContext)
    -> RGBAColor
  {
    let markers = context.markers[index] ?? []
    if markers.contains(Marker.primary) {
      return Self.primaryColor
    }
    if markers.contains(Marker.secondary) {
      return Self.secondaryColor
    }
    return .hueRamp(normalized)
  }
}
