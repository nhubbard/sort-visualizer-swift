import Foundation
import SortEngineKit
import VisualizationKit

/// Describes the image mosaic independently of its Metal texture resource.
public struct CustomImageVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "customimage")
  public let metadata = VisualizerMetadata(
    displayName: String(localized: "Custom Image", bundle: .module),
    supportsAuxArrays: false, iconName: "photo.on.rectangle.angled")

  public init() {}

  public func draw(_ context: VisualizationContext) -> [DrawCommand] {
    guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0
    else { return [] }
    let layout = ImageTileLayout(
      count: context.values.count,
      aspectRatio: context.imageAspectRatio
        ?? Double(context.canvasSize.width / context.canvasSize.height))
    return (0..<layout.cellCount).map { slot in
      let rect = layout.rect(for: slot, in: context.canvasSize)
      let marker = slot < layout.movingCount ? context.markers[slot] ?? [] : []
      let markerKind = marker.contains(Marker.primary) ? 1
        : marker.contains(Marker.secondary) ? 2 : 0
      return .imageTile(
        x: Double(rect.minX), y: Double(rect.minY),
        width: Double(rect.width), height: Double(rect.height),
        sourceSlot: layout.sourceSlot(
          forDestination: slot, values: context.values, valueRange: context.valueRange),
        marker: markerKind)
    }
  }
}
