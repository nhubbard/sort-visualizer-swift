import CoreGraphics

/// A rectangular image grid with one moving cell per array item. Any spare cells retain their
/// original image fragment, so the completed picture has no missing edge or corner.
public struct ImageTileLayout: Sendable, Equatable {
  public let columns: Int
  public let rows: Int
  public let movingCount: Int

  public var cellCount: Int { columns * rows }

  public init(count: Int, aspectRatio: Double) {
    movingCount = max(0, count)
    guard count > 0 else {
      columns = 0
      rows = 0
      return
    }
    let aspect = aspectRatio.isFinite && aspectRatio > 0
      ? min(4, max(0.25, aspectRatio)) : 1
    columns = max(1, min(count, Int((Double(count) * aspect).squareRoot().rounded(.up))))
    rows = (count + columns - 1) / columns
  }

  public func sourceSlot(forValue value: Int, valueRange: ClosedRange<Int>) -> Int {
    guard movingCount > 1 else { return 0 }
    let low = valueRange.lowerBound
    let high = valueRange.upperBound
    guard high > low else { return 0 }
    let fraction = Double(value) - Double(low)
    let span = Double(high) - Double(low)
    let normalized = max(0, min(1, fraction / span))
    return min(movingCount - 1, Int((normalized * Double(movingCount - 1)).rounded()))
  }

  public func sourceSlot(forDestination slot: Int, values: [Int],
                         valueRange: ClosedRange<Int>) -> Int {
    guard (0..<cellCount).contains(slot) else { return 0 }
    if slot >= movingCount { return slot }
    return sourceSlot(forValue: values[slot], valueRange: valueRange)
  }

  public func rect(for slot: Int, in size: CGSize) -> CGRect {
    guard columns > 0, rows > 0, (0..<cellCount).contains(slot) else { return .zero }
    let width = size.width / CGFloat(columns)
    let height = size.height / CGFloat(rows)
    return CGRect(x: CGFloat(slot % columns) * width,
                  y: CGFloat(slot / columns) * height, width: width, height: height)
  }
}
