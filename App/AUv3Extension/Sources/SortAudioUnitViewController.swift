import AudioToolbox
import CoreAudioKit
import SortAudioUnitKit

/// The extension's principal class (`NSExtensionPrincipalClass` in this target's Info.plist). Must
/// be an `AUViewController` subclass, not a bare `NSObject` — `com.apple.AudioUnit-UI`'s
/// view-vending/ViewBridge machinery expects the principal class to actually be a view controller
/// for this extension point. A bare `AUAudioUnitFactory`-conforming `NSObject` (the previous
/// `SortAudioUnitFactory`) left PlugInKit logging "misconfigured plugin; external subsystem
/// [NSViewService_PKSubsystem] not present; possible missing linkage" at launch, and Logic Pro
/// would register the component but silently time out a few minutes later without ever calling
/// `allocateRenderResources()` — this fixes that by providing a real, if minimal, view controller.
///
/// Vends only a placeholder view for now; the real audio-production-only parameter view (envelope
/// ADSR, detune, gain) is a planned follow-on (AUDIO_UNIT_PLAN.md §7's "Plug-in UI" subsection),
/// not built here. `beginRequest(with:)` needs no override — `AUViewController`'s own superclass
/// chain already conforms to `NSExtensionRequestHandling`, unlike the bare `NSObject` this replaces.
final class SortAudioUnitViewController: AUViewController, AUAudioUnitFactory {
  /// `AUAudioUnitFactory.createAudioUnit(with:)` isn't main-actor-isolated (a host may call it from
  /// any thread), but `AUViewController` itself is — `nonisolated(unsafe)` matches the standard
  /// AUv3 idiom of keeping a strong reference to the created unit from the view controller purely to
  /// keep it alive and to let a later-loaded UI find it; there's no concurrent mutation of this
  /// property to protect against, only a single assignment at creation time.
  private nonisolated(unsafe) var audioUnit: SortAudioUnit?

  nonisolated func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    let audioUnit = try SortAudioUnit(componentDescription: componentDescription, options: [])
    self.audioUnit = audioUnit
    return audioUnit
  }
}
