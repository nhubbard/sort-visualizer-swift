import CoreGraphics
import MetalKit

/// Every concrete Metal renderer (`MetalBarRenderer`, `MetalShapeRenderer<Layout>`) needs
/// `onDrawableSizeChange` in addition to the shared `IncrementalBarRenderer` contract — see
/// `MetalBarRenderer`'s own doc comment on that property for why `MTKView`'s size-change delegate
/// callback, not `updateUIView`'s polling, is the only reliable "you have somewhere real to render"
/// signal. Pulling it into one protocol lets `MetalRendererFactory`/`MetalRendererView.Coordinator`
/// hold a single existential (`any MetalIncrementalRenderer`) instead of switching on which
/// concrete renderer type is currently active.
@MainActor
protocol MetalIncrementalRenderer: IncrementalBarRenderer, MTKViewDelegate {
    var onDrawableSizeChange: ((CGSize) -> Void)? { get set }

    /// `false` (today's exact instant-snap-to-target behavior) unless `MetalRendererView` turns it
    /// on — set from `AppSettings.reduceFlashingEffective` (the user's manual toggle, OR'd with the
    /// system's Reduce Motion accessibility setting). When `true`, `apply`'s per-touched-index color
    /// writes fade over a short transition instead of snapping — see `MetalColorTransitionTracker`.
    var reduceFlashingEnabled: Bool { get set }
}
