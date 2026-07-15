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
}
