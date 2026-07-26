import MetalKit
import SortEngineKit
import SwiftUI
import UIKit
import VisualizationKit

/// Bridges whichever `MetalIncrementalRenderer` `MetalRendererFactory` builds for `visualizerID`
/// into SwiftUI. `.id(ObjectIdentifier(replay))` at the call site (`SortView.canvas(for:)`)
/// matters: a new run needs a fresh `Coordinator`'s tracking state, not a stale one left over from
/// a previous, possibly differently-sized (or differently-styled) run.
struct MetalRendererView: UIViewRepresentable {
  let replay: ReplayEngine
  let visualizerID: VisualizerID

  @Environment(\.colorScheme) private var colorScheme

  func makeUIView(context: Context) -> MTKView {
    let view = MTKView()
    // Always opaque, never transparent — the visualization plane paints its own backdrop
    // rather than showing whatever's behind it through. Which color that backdrop actually is
    // (and the "no marker" default item color that has to stay visible against it) flips with
    // the system appearance — see `Coordinator.setColorScheme`.
    view.isOpaque = true
    view.layer.isOpaque = true
    context.coordinator.setColorScheme(colorScheme, view: view)
    // `isPaused = true` + `enableSetNeedsDisplay = true` puts this view on the SAME clock as
    // `ReplayEngine.onOperationApplied` (which explicitly calls `setNeedsDisplay()` below)
    // instead of MTKView's own independent internal display-link loop, which redrew
    // unconditionally every vsync — including every idle frame where the sort had produced
    // nothing new — so this only redraws when `replay.frame` actually changes, not strictly
    // more than that.
    view.isPaused = true
    view.enableSetNeedsDisplay = true
    // Only takes effect while a renderer flips `isPaused` to `false` for an in-flight
    // color/geometry transition (see `MetalBarRenderer.draw(in:)`'s own doc comment) — caps
    // MetalKit's own internal display link to 30fps instead of the display's full native
    // refresh rate, so a sustained fade doesn't compete with SwiftUI's own animations for
    // main-thread time. No effect at all while `isPaused == true` (today's default).
    view.preferredFramesPerSecond = 30
    guard let device = MTLCreateSystemDefaultDevice() else { return view }
    view.device = device
    // The highest MSAA sample count this device actually supports (see `MetalSampleCount`) —
    // smooths the hard-pixelated edges the GPU shapes would otherwise have. Must be set before
    // building the renderer: its pipeline's `rasterSampleCount` has to match this exactly.
    let sampleCount = MetalSampleCount.preferred(for: device)
    view.sampleCount = sampleCount
    guard
      let renderer = MetalRendererFactory.makeRenderer(
        for: visualizerID, device: device, sampleCount: sampleCount)
    else {
      return view
    }
    // Wire the Coordinator (which sets `renderer.onDrawableSizeChange`) BEFORE handing the
    // renderer to the view as its delegate — eliminates any chance of the view's very first
    // layout firing `drawableSizeWillChange` before anything is listening for it.
    context.coordinator.setUp(
      replay: replay, renderer: renderer, view: view, visualizerID: visualizerID)
    view.delegate = renderer
    return view
  }

  func updateUIView(_ view: MTKView, context: Context) {
    // Read fresh on every body evaluation — the only way a live Light/Dark Mode change reaches
    // an already-built view/renderer. `setColorScheme` itself no-ops unless the value actually
    // changed.
    context.coordinator.setColorScheme(colorScheme, view: view)
    // `.id(ObjectIdentifier(replay))` at the call site only forces a fresh view (and thus a
    // fresh `makeUIView`) for a genuinely NEW run — switching visualizers mid-sort (⌘⇧V, or
    // the Settings picker) keeps the SAME `replay`, so this is the only place that ever learns
    // about it. Must run before `reconcileStepIndexIfNeeded()`: that call is a no-op unless
    // `stepIndex` itself moved, which switching visualizers alone doesn't change, but the new
    // renderer's buffer still needs its own first full seed.
    context.coordinator.switchVisualizerIfNeeded(to: visualizerID, view: view)
    // Catches a scrub/seek (`stepIndex` changing without `onOperationApplied` firing, by
    // `ReplayEngine`'s design) — a no-op during normal playback since `trackedStepIndex` already
    // matches. Resize is handled separately by `onDrawableSizeChange`: `view.drawableSize` can
    // still be `.zero` here before real layout happens, with no guarantee `updateUIView` runs
    // again once it becomes valid.
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
    private var renderer: (any MetalIncrementalRenderer)?
    private var view: MTKView?
    private var trackedStepIndex = -1
    private var visualizerID: VisualizerID?
    /// Last `\.colorScheme` actually applied — this view is on-demand (`isPaused`/
    /// `enableSetNeedsDisplay`), so without this cache every single body evaluation would force
    /// a redundant `setNeedsDisplay()`, not just an actual Light/Dark Mode change. `nil` before
    /// the first call, so the very first `makeUIView` always applies regardless of value.
    private var appliedColorScheme: ColorScheme?

    /// The canvas backdrop (`view.clearColor`) and the shared "no marker at all" default color
    /// (`MetalBarRenderer.defaultColor`/`MetalShapeColor.neutral`) both have to flip together —
    /// a near-white default bar is only readable against a dark backdrop, and vice versa. The
    /// latter two are process-wide statics rather than per-renderer state because they're a
    /// shared visual constant, not something that varies per algorithm/visualizer instance.
    func setColorScheme(_ colorScheme: ColorScheme, view: MTKView) {
      guard colorScheme != appliedColorScheme else { return }
      appliedColorScheme = colorScheme
      view.clearColor = Self.clearColor(for: colorScheme)
      MetalBarRenderer.defaultColor = Self.neutralColor(for: colorScheme)
      MetalShapeColor.neutral = Self.neutralColor(for: colorScheme)
      view.setNeedsDisplay()
    }

    private static func clearColor(for colorScheme: ColorScheme) -> MTLClearColor {
      #if targetEnvironment(macCatalyst)
        // On Mac Catalyst, the canvas sits inside a windowed app next to sidebar/toolbar
        // chrome that already uses the system background — a fixed black (or the iPad's
        // fixed near-white) reads as visibly out of place there, so follow the same
        // adaptive color the surrounding chrome uses instead of a hardcoded constant.
        return systemBackgroundClearColor(for: colorScheme)
      #else
        return colorScheme == .light
          ? MTLClearColor(red: 0.90, green: 0.90, blue: 0.93, alpha: 1)
          : MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
      #endif
    }

    #if targetEnvironment(macCatalyst)
      private static func systemBackgroundClearColor(for colorScheme: ColorScheme) -> MTLClearColor {
        let trait = UITraitCollection(userInterfaceStyle: colorScheme == .light ? .light : .dark)
        let resolved = UIColor.systemBackground.resolvedColor(with: trait)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return MTLClearColor(red: Double(red), green: Double(green), blue: Double(blue), alpha: 1)
      }
    #endif

    private static func neutralColor(for colorScheme: ColorScheme) -> SIMD4<Float> {
      colorScheme == .light ? SIMD4<Float>(0.30, 0.30, 0.34, 1) : SIMD4<Float>(0.82, 0.82, 0.86, 1)
    }

    func setUp(
      replay: ReplayEngine, renderer: any MetalIncrementalRenderer, view: MTKView,
      visualizerID: VisualizerID
    ) {
      self.replay = replay
      self.renderer = renderer
      self.view = view
      self.visualizerID = visualizerID
      trackedStepIndex = -1

      replay.onOperationApplied = { [weak self, weak replay, weak renderer] operation in
        guard let self, let replay, let renderer else { return }
        let values = replay.frame.map(\.value)
        renderer.apply(
          operation, values: values, valueRange: Self.valueRange(for: values),
          markers: Self.markers(for: replay.frame)
        )
        self.trackedStepIndex += 1
        // Multiple operations can land here within the same `CADisplayLink` tick (catch-up
        // batching during fast playback) — `setNeedsDisplay()` just marks the view dirty,
        // so N calls before the next vsync still coalesce into exactly one `draw(in:)`,
        // one redraw per tick with the final state, rather than drawing every intermediate
        // step.
        self.view?.setNeedsDisplay()

        // Forces a synchronous extra draw when playback reaches natural completion, on top of
        // the routine `setNeedsDisplay()` above: a long monotonic run of single-index writes at
        // the very end (e.g. Counting Sort's final pass) could leave a stale tail on screen even
        // though the instance buffer is already fully correct, since nothing else was guaranteed
        // to trigger another redraw. Costs nothing during normal playback.
        if replay.stepIndex >= replay.totalOperationCount {
          self.view?.draw()
        }
      }

      // The authoritative "you have a real size now" signal — see this callback's own doc
      // comment on `MetalBarRenderer` for why `updateUIView`'s own polling isn't enough by
      // itself. Fires immediately with the view's current size too (MTKView calls this once
      // as soon as it has one), so this alone covers first-appearance, not just later resizes.
      renderer.onDrawableSizeChange = { [weak self] pixelSize in
        self?.reconcile(pixelSize: pixelSize)
      }
    }

    /// Rebuilds the renderer when `visualizerID` changed since `setUp`/the last switch — the
    /// only place this can happen, since `.id(ObjectIdentifier(replay))` at the call site keeps
    /// this same `Coordinator`/`MTKView` alive across a mid-sort visualizer change (only a
    /// genuinely new `replay` tears them down). Reuses `view.device`/`view.sampleCount` (both
    /// already set once in `makeUIView`) so the new pipeline's `rasterSampleCount` still
    /// matches what this view actually renders into.
    func switchVisualizerIfNeeded(to newVisualizerID: VisualizerID, view: MTKView) {
      guard
        newVisualizerID != visualizerID, let replay, let device = view.device,
        let newRenderer = MetalRendererFactory.makeRenderer(
          for: newVisualizerID, device: device, sampleCount: view.sampleCount)
      else { return }

      setUp(replay: replay, renderer: newRenderer, view: view, visualizerID: newVisualizerID)
      view.delegate = newRenderer
      // `onDrawableSizeChange` won't fire again on its own here — that callback only fires
      // on a REAL drawable-size change, and swapping the delegate isn't one. The new
      // renderer's buffer starts out empty otherwise, so this is the only seed it gets.
      reconcile(pixelSize: view.drawableSize)
    }

    func reconcileStepIndexIfNeeded() {
      guard let replay, replay.stepIndex != trackedStepIndex, let view else { return }
      reconcile(pixelSize: view.drawableSize)
    }

    /// Test seam: lets a test verify a mid-sort visualizer switch actually rebuilt the
    /// renderer (a genuinely different instance, freshly seeded) rather than just updating
    /// bookkeeping with nothing behind it.
    func debugState() -> (visualizerID: VisualizerID?, renderer: (any MetalIncrementalRenderer)?) {
      (visualizerID, renderer)
    }

    private func reconcile(pixelSize: CGSize) {
      guard let replay, let renderer, let view else { return }
      let scale = view.contentScaleFactor
      guard scale > 0, pixelSize.width > 0, pixelSize.height > 0 else { return }
      let canvasSize = CGSize(width: pixelSize.width / scale, height: pixelSize.height / scale)

      let values = replay.frame.map(\.value)
      renderer.reset(
        values: values, valueRange: Self.valueRange(for: values),
        markers: Self.markers(for: replay.frame),
        canvasSize: canvasSize, scale: scale
      )
      trackedStepIndex = replay.stepIndex
      // A resize (e.g. `RunControlBar`'s `safeAreaInset` coming or going) changes the
      // `CAMetalLayer`'s on-screen size the moment SwiftUI/UIKit commits the new layout —
      // ahead of `setNeedsDisplay()`'s deferred, next-vsync `draw(in:)` on this `isPaused`/
      // on-demand view. That gap could show one frame where the layer is already the new
      // size but `renderer`'s instance buffer still holds geometry sized for the old one —
      // a mis-scaled/letterboxed flash. Same forced-synchronous-draw fix as the completion
      // path above, applied here instead of relying on `setNeedsDisplay()` alone.
      view.draw()
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
