import AlgorithmKit
import SortEngineKit

/// `SortSession` calls `record(...)` after `phase` transitions to `.complete` — never from inside
/// recording or replay, so the engine has zero knowledge that analytics exist at all (§3.2).
///
/// No-op until Phase 8 wires up real SwiftData/CloudKit persistence: `SortSession` already calls
/// this at the right point in its lifecycle, so Phase 8 only needs to fill in this body, not touch
/// any call site.
public actor AnalyticsService {
    public init() {}

    public func record(_ header: TapeHeader, algorithmID: AlgorithmID) async throws {}
}
