#if DEBUG
import AlgorithmKit
import PersistenceKit
import SortEngineKit
import SwiftUI

/// Test-only controls at the app root, before any sort session is opened. This isolates the
/// SwiftData/CloudKit check from replay and from UI-test idle waits on an animated sort.
public struct CloudKitCanaryControls: View {
  private let marker: String
  @State private var status = "not checked"

  public init(marker: String) { self.marker = marker }

  public var body: some View {
    HStack {
      Button("Write sync canary") {
        Task { await writeCanary() }
      }
      .accessibilityIdentifier("cloudKitCanaryWriteButton")
      Button("Refresh sync canary") {
        Task { await refreshCanary() }
      }
      .accessibilityIdentifier("cloudKitCanaryRefreshButton")
      Button("Delete sync canary") {
        Task { await deleteCanary() }
      }
      .accessibilityIdentifier("cloudKitCanaryDeleteButton")
      Text("CloudKit canary")
        .accessibilityIdentifier("cloudKitCanaryProbe")
        .accessibilityValue(status)
    }
    .task {
      switch ProcessInfo.processInfo.environment["UI_TEST_CLOUDKIT_CANARY_ACTION"] {
      case "write":
        await writeCanary()
      case "observe":
        for _ in 0..<60 {
          await refreshCanary()
          if status == "count:1" { break }
          try? await Task.sleep(for: .seconds(5))
        }
      case "observeDelete":
        for _ in 0..<120 {
          await refreshCanary()
          if status == "count:0" { break }
          try? await Task.sleep(for: .seconds(5))
        }
      case "delete":
        await deleteCanary()
      default:
        break
      }
    }
  }

  private func writeCanary() async {
    status = "opening store"
    do {
      let service = AnalyticsService.shared
      status = "checking existing record"
      if try await service.syncCanaryCountForUITesting(marker: marker) == 0 {
        status = "saving record"
        try await service.record(
          TapeHeader(
            algorithmID: marker, initialValues: [1], visualSeed: 0,
            compareCount: 0, swapCount: 0, recordingDuration: 0,
            recordedAt: Date()),
          algorithmID: AlgorithmID(rawValue: marker))
      }
      status = "checking saved record"
      let count = try await service.syncCanaryCountForUITesting(marker: marker)
      status = "count:\(count)"
    } catch { status = "error:\(error)" }
  }

  private func refreshCanary() async {
    do {
      let count = try await AnalyticsService.shared.syncCanaryCountForUITesting(marker: marker)
      status = "count:\(count)"
    } catch { status = "error:\(error)" }
  }

  private func deleteCanary() async {
    do {
      try await AnalyticsService.shared.deleteSyncCanaryForUITesting(marker: marker)
      status = "count:0"
    } catch { status = "error:\(error)" }
  }
}
#endif
