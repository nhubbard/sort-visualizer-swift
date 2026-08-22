import AudioToolbox
import CoreAudioKit
import SortAudioUnitKit
import SwiftUI
import UIKit

/// The extension's principal class (`NSExtensionPrincipalClass` in this target's Info.plist). Must
/// be an `AUViewController` subclass, not a bare `NSObject` — `com.apple.AudioUnit-UI`'s
/// view-vending/ViewBridge machinery expects the principal class to actually be a view controller
/// for this extension point. A bare `AUAudioUnitFactory`-conforming `NSObject` (the previous
/// `SortAudioUnitFactory`) left PlugInKit logging "misconfigured plugin; external subsystem
/// [NSViewService_PKSubsystem] not present; possible missing linkage" at launch, and Logic Pro
/// would register the component but silently time out a few minutes later without ever calling
/// `allocateRenderResources()` — this fixes that by providing a real, if minimal, view controller.
///
/// Vends the remote (see Documentation/docs/architecture/audio.md's "The plug-in UI") — sort transport buttons plus
/// audio-production-only DSP sliders — hosted via `UIHostingController` since the SwiftUI view
/// itself lives in `SortAudioUnitParameterView.swift`. `beginRequest(with:)` needs no override —
/// `AUViewController`'s own superclass chain already conforms to `NSExtensionRequestHandling`,
/// unlike the bare `NSObject` this replaces.
///
/// Per Apple's own AUv3 guidance, the view and the audio unit can finish loading in either order —
/// `viewDidLoad` and the end of `createAudioUnit(with:)` both attempt to connect the two, whichever
/// happens second is the one that actually builds the hosted SwiftUI view.
final class SortAudioUnitViewController: AUViewController, AUAudioUnitFactory {
  /// `AUAudioUnitFactory.createAudioUnit(with:)` isn't main-actor-isolated (a host may call it from
  /// any thread), but `AUViewController` itself is — `nonisolated(unsafe)` matches the standard
  /// AUv3 idiom of keeping a strong reference to the created unit from the view controller purely to
  /// keep it alive and to let a later-loaded UI find it; there's no concurrent mutation of this
  /// property to protect against, only a single assignment at creation time.
  private nonisolated(unsafe) var audioUnit: SortAudioUnit?
  private var hostingController: UIHostingController<SortAudioUnitParameterView>?

  override func viewDidLoad() {
    super.viewDidLoad()
    preferredContentSize = CGSize(width: 420, height: 420)
    connectViewToAudioUnitIfPossible()
  }

  nonisolated func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    let audioUnit = try SortAudioUnit(componentDescription: componentDescription, options: [])
    self.audioUnit = audioUnit
    Task { @MainActor [weak self] in
      self?.connectViewToAudioUnitIfPossible()
    }
    return audioUnit
  }

  private func connectViewToAudioUnitIfPossible() {
    guard isViewLoaded, let audioUnit, hostingController == nil else { return }

    let hosting = UIHostingController(rootView: SortAudioUnitParameterView(audioUnit: audioUnit))
    addChild(hosting)
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hosting.view)
    NSLayoutConstraint.activate([
      hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
      hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    hosting.didMove(toParent: self)
    hostingController = hosting
  }
}
