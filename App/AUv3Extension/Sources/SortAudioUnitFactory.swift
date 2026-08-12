import AudioToolbox
import Foundation
import SortAudioUnitKit

/// The extension's principal class (`NSExtensionPrincipalClass` in this target's Info.plist) — a
/// thin factory in the extension's own bundle that just forwards to `SortAudioUnitKit`'s real
/// implementation, matching the standard, proven AUv3 pattern (a linked framework holds the actual
/// `AUAudioUnit` subclass; the extension target itself is little more than this glue plus the
/// Info.plist declaring it).
///
/// `NSExtensionRequestHandling.beginRequest(with:)` is a no-op: it's the generic app-extension
/// entry point most extension types (share, action, etc.) actually use, normally satisfied for
/// free by `AUViewController` in UI-providing AU templates. Since this extension has no custom
/// view controller, the principal class needs an explicit (if unused) conformance — AUv3 hosts
/// reach this unit through `AUAudioUnitFactory.createAudioUnit(with:)` below, not this method.
final class SortAudioUnitFactory: NSObject, AUAudioUnitFactory {
  func beginRequest(with context: NSExtensionContext) {}

  func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    try SortAudioUnit(componentDescription: componentDescription, options: [])
  }
}
