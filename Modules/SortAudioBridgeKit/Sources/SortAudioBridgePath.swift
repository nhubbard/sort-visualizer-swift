import Foundation

/// Where the companion-mode bridge's Unix domain socket lives — inside the shared App Group
/// container, per Apple's own guidance (confirmed via Apple DTS forum posts, not just community
/// folklore) that this is the supported, sandbox-compatible mechanism for two otherwise-unrelated
/// sandboxed processes (the standalone app and an AU extension hosted by a third-party DAW) to talk
/// directly, unlike a custom XPC/Mach service listener.
public enum SortAudioBridgePath {
  public static let appGroupIdentifier = "group.com.nhubbard.Sort2.mobile"

  /// Kept deliberately short: `sockaddr_un.sun_path` has a 104-byte limit on Darwin, and a full App
  /// Group container path (`~/Library/Group Containers/<TeamID>.<AppGroupID>/...`) already eats
  /// most of that budget before the filename is even considered.
  private static let socketFileName = "b.sock"

  /// A conservative ceiling, not the literal 104-byte `sun_path` limit itself — leaves headroom for
  /// however the underlying `bind`/`connect` call actually accounts for the trailing NUL and any
  /// path normalization, rather than assuming this call site's arithmetic matches the kernel's
  /// exactly.
  private static let maxSafeByteCount = 100

  /// `nil` if the App Group entitlement isn't present/provisioned (e.g. a test target, or signing
  /// not yet configured) — both the server and client sides treat that as "bridge unavailable" and
  /// fall back to their own non-bridge behavior rather than crashing.
  public static func socketPath(fileManager: FileManager = .default) -> String? {
    guard let containerURL = fileManager.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    else { return nil }
    let path = containerURL.appendingPathComponent(socketFileName).path
    guard path.utf8.count <= maxSafeByteCount else { return nil }
    return path
  }
}
