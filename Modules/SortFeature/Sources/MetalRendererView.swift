import MetalKit
import SortEngineKit
import SwiftUI

/// Bridges `MetalBarRenderer` into SwiftUI. `.id(ObjectIdentifier(replay))` at the call site
/// (`SortView.canvas(for:)`) matters: a new run needs a fresh `Coordinator`'s tracking state, not
/// a stale one left over from a previous, possibly differently-sized run.
struct MetalRendererView: UIViewRepresentable {
    let replay: ReplayEngine

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.isOpaque = false
        view.layer.isOpaque = false
        // Both already the documented defaults — explicit so "does MTKView even run its own
        // draw loop" isn't one more thing to guess about while chasing the blank-screen bug.
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        guard let device = MTLCreateSystemDefaultDevice(), let renderer = MetalBarRenderer(device: device) else {
            return view
        }
        view.device = device
        // Wire the Coordinator (which sets `renderer.onDrawableSizeChange`) BEFORE handing the
        // renderer to the view as its delegate — eliminates any chance of the view's very first
        // layout firing `drawableSizeWillChange` before anything is listening for it.
        context.coordinator.setUp(replay: replay, renderer: renderer, view: view)
        view.delegate = renderer
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        // Catches a scrub/seek (`stepIndex` changing without `onOperationApplied` ever firing,
        // by `ReplayEngine`'s own design) — normal incremental playback is a no-op here, since
        // `trackedStepIndex` already matches by the time this runs. Resize is handled separately,
        // by `MetalBarRenderer.onDrawableSizeChange` below — `view.drawableSize` can still be
        // `.zero` the first several times this is called, before real layout ever happens, with
        // no guarantee SwiftUI calls `updateUIView` again once it becomes valid; the dedicated
        // resize callback is the only signal that's actually guaranteed to fire when a real size
        // shows up.
        context.coordinator.reconcileStepIndexIfNeeded()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator {
        // `replay`'s real owner is `SortSession.phase` (`.replaying`/`.complete`), which already
        // keeps it alive for as long as this run is current — `weak` here just avoids the
        // Coordinator extending that lifetime on its own. `renderer`/`view` are the opposite case:
        // `MTKView.delegate` is itself `weak` (Apple's own declaration), and nothing else outside
        // this Coordinator retains either one — `weak` here would let both deallocate the instant
        // `makeUIView` returns, leaving `view.delegate` dangling and this whole renderer inert.
        private weak var replay: ReplayEngine?
        private var renderer: MetalBarRenderer?
        private var view: MTKView?
        private var trackedStepIndex = -1

        func setUp(replay: ReplayEngine, renderer: MetalBarRenderer, view: MTKView) {
            self.replay = replay
            self.renderer = renderer
            self.view = view
            trackedStepIndex = -1

            replay.onOperationApplied = { [weak self, weak replay, weak renderer] operation in
                guard let self, let replay, let renderer else { return }
                let values = replay.frame.map(\.value)
                renderer.apply(
                    operation, values: values, valueRange: Self.valueRange(for: values),
                    markers: Self.markers(for: replay.frame)
                )
                self.trackedStepIndex += 1
            }

            // The authoritative "you have a real size now" signal — see this callback's own doc
            // comment on `MetalBarRenderer` for why `updateUIView`'s own polling isn't enough by
            // itself. Fires immediately with the view's current size too (MTKView calls this once
            // as soon as it has one), so this alone covers first-appearance, not just later resizes.
            renderer.onDrawableSizeChange = { [weak self] pixelSize in
                self?.reconcile(pixelSize: pixelSize)
            }
        }

        func reconcileStepIndexIfNeeded() {
            guard let replay, replay.stepIndex != trackedStepIndex, let view else { return }
            reconcile(pixelSize: view.drawableSize)
        }

        private func reconcile(pixelSize: CGSize) {
            guard let replay, let renderer, let view else { return }
            let scale = view.contentScaleFactor
            guard scale > 0, pixelSize.width > 0, pixelSize.height > 0 else { return }
            let canvasSize = CGSize(width: pixelSize.width / scale, height: pixelSize.height / scale)

            let values = replay.frame.map(\.value)
            renderer.reset(
                values: values, valueRange: Self.valueRange(for: values), markers: Self.markers(for: replay.frame),
                canvasSize: canvasSize, scale: scale
            )
            trackedStepIndex = replay.stepIndex
        }

        private static func valueRange(for values: [Int]) -> ClosedRange<Int> {
            guard let minValue = values.min(), let maxValue = values.max(), minValue < maxValue else {
                return 0...1
            }
            return minValue...maxValue
        }

        private static func markers(for frame: [ReplayEngine.BarState]) -> [Int: Set<Int>] {
            Dictionary(uniqueKeysWithValues: frame.enumerated().map { ($0.offset, $0.element.markers) })
        }
    }
}
