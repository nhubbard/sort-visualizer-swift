import SortEngineKit
import SwiftUI

enum TeachingGraphPlaybackPolicy {
  static let readingRate = 1.0
  static let minimumReadingTime: TimeInterval = 3

  static func shouldPin(isPlaying: Bool, pacingRate: Double) -> Bool {
    isPlaying && pacingRate > readingRate
  }

  static func shouldUpdate(
    isPlaying: Bool, isPinned: Bool, now: Date, lastUpdate: Date
  ) -> Bool {
    !isPinned && (!isPlaying || now.timeIntervalSince(lastUpdate) >= minimumReadingTime)
  }
}

/// The graph follows the same ReplayEngine as the Metal canvas.
struct TeachingGraphSection: View {
  let session: SortSession

  var body: some View {
    if let replay = session.lastReplay,
      (replay.tape.header.algorithmID == "quicksort"
        || replay.tape.header.algorithmID == "mergesort"
        || !replay.tape.teachingAnnotations.isEmpty) {
      TeachingGraphView(replay: replay)
        .id(ObjectIdentifier(replay))
        .padding(.horizontal)
        .padding(.vertical, 16)
    }
  }
}

private struct TeachingGraphView: View {
  let replay: ReplayEngine
  @State private var trace: TeachingGraphTrace
  @State private var isExpanded = false
  @State private var displayedStep: Int
  @State private var isPinned = false
  @State private var lastAutomaticUpdate = Date.distantPast

  init(replay: ReplayEngine) {
    self.replay = replay
    _trace = State(initialValue: TeachingGraphTrace(tape: replay.tape)!)
    _displayedStep = State(initialValue: replay.stepIndex)
  }

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      if isExpanded {
        let step = displayedStep
        let snapshot = trace.snapshot(at: step)
        VStack(alignment: .leading, spacing: 12) {
          Text(introduction)
            .font(.subheadline)
            .foregroundStyle(.secondary)
          if isPinned {
            Text("Pinned while playback is fast")
              .font(.caption)
              .foregroundStyle(.secondary)
              .accessibilityIdentifier("teachingGraphPinnedStatus")
          }
          if let event = snapshot.current {
            Text("Graph event \(snapshot.currentNumber) of \(trace.events.count)")
              .font(.caption.monospacedDigit())
              .foregroundStyle(.secondary)
            Text(event.explanation)
              .font(.body)
              .accessibilityIdentifier("teachingGraphExplanation")
            TeachingGraphCanvas(snapshot: snapshot)
              .frame(height: snapshot.nodes.contains { $0.location != .array } ? 160 : 110)
              .accessibilityHidden(true)
            Text(legend(for: snapshot))
              .font(.caption)
              .foregroundStyle(.secondary)
            Text("Showing up to \(TeachingGraphTrace.maximumVisibleEvents) recent events and \(TeachingGraphTrace.maximumVisibleNodes) items.")
              .font(.caption)
              .foregroundStyle(.secondary)
          } else {
            Text(isPinned
              ? "Pause or slow playback to read decisions."
              : (step < trace.sortStartIndex
                ? "The graph begins after the shuffle."
                : "Use Next Graph Event to reach the first decision."))
              .accessibilityIdentifier("teachingGraphExplanation")
          }
          HStack {
            Button("Previous Graph Event") {
              if let target = trace.previousStep(before: step) { replay.seek(to: target) }
            }
            .disabled(trace.previousStep(before: step) == nil)
            .accessibilityIdentifier("teachingGraphPreviousButton")
            Button("Next Graph Event") {
              if let target = trace.nextStep(after: step) { replay.seek(to: target) }
            }
            .disabled(trace.nextStep(after: step) == nil)
            .accessibilityIdentifier("teachingGraphNextButton")
          }
          .buttonStyle(.bordered)
        }
        .padding(.top, 10)
      }
    } label: {
      Label("Teaching Graph", systemImage: "point.3.connected.trianglepath.dotted")
        .font(.title2.bold())
        .accessibilityIdentifier("teachingGraphDisclosure")
    }
    .task(id: isExpanded) {
      guard isExpanded else { return }
      while !Task.isCancelled {
        let playing = replay.isPlaying
        let fast = TeachingGraphPlaybackPolicy.shouldPin(
          isPlaying: playing, pacingRate: replay.currentPacingRate)
        if isPinned != fast { isPinned = fast }
        let now = Date()
        if TeachingGraphPlaybackPolicy.shouldUpdate(
          isPlaying: playing, isPinned: fast, now: now,
          lastUpdate: lastAutomaticUpdate), displayedStep != replay.stepIndex {
          displayedStep = replay.stepIndex
          lastAutomaticUpdate = now
        }
        try? await Task.sleep(for: .milliseconds(100))
      }
    }
  }

  private var introduction: String {
    switch trace.variant {
    case .quickSort:
      "Quick Sort compares each partition's pivot with other positions, moves values within the partition, then places the pivot."
    case .mergeSort:
      "Merge Sort compares two runs, moves chosen values into a temporary buffer, then writes them back to the array."
    case .annotated:
      "Follow the algorithm's recorded decisions and movements. Each explanation describes the reason for a marked step."
    }
  }

  private func legend(for snapshot: TeachingGraphTrace.Snapshot) -> String {
    var legend = "Dashed connections show decisions; solid connections show movement."
    if snapshot.nodes.contains(where: { $0.location == .buffer }) {
      legend += " B marks a temporary buffer position."
    }
    if snapshot.nodes.contains(where: { $0.location == .value }) {
      legend += " V marks a held value."
    }
    return legend
  }
}

private struct TeachingGraphCanvas: View {
  let snapshot: TeachingGraphTrace.Snapshot

  var body: some View {
    Canvas { context, size in
      let nodes = snapshot.nodes
      let arrays = nodes.filter { $0.location == .array }
      let buffers = nodes.filter { $0.location == .buffer }
      let values = nodes.filter { $0.location == .value }
      let hasLowerRow = !buffers.isEmpty || !values.isEmpty

      func point(for node: TeachingGraphTrace.Node) -> CGPoint {
        let row: [TeachingGraphTrace.Node]
        switch node.location {
        case .array: row = arrays
        case .buffer: row = buffers
        case .value: row = values
        }
        let position = row.firstIndex(of: node) ?? 0
        let spacing = (size.width - 36) / CGFloat(max(row.count - 1, 1))
        let x = row.count == 1 ? size.width / 2 : 18 + CGFloat(position) * spacing
        let y: CGFloat
        switch node.location {
        case .array: y = hasLowerRow ? 35 : size.height / 2
        case .buffer: y = arrays.isEmpty && values.isEmpty ? size.height / 2
          : values.isEmpty ? size.height - 35 : size.height / 2
        case .value: y = arrays.isEmpty && buffers.isEmpty ? size.height / 2 : size.height - 35
        }
        return CGPoint(x: x, y: y)
      }

      for (index, event) in snapshot.events.enumerated() {
        let source = point(for: event.source)
        let target = point(for: event.target)
        var path = Path()
        path.move(to: source)
        if source == target {
          path.addArc(center: CGPoint(x: source.x + 10, y: source.y - 10), radius: 10,
                      startAngle: .degrees(90), endAngle: .degrees(350), clockwise: false)
        } else {
          path.addLine(to: target)
        }
        let isCurrent = index == snapshot.events.count - 1
        let color: Color = event.kind == .decision ? .purple : .orange
        context.stroke(path, with: .color(color.opacity(isCurrent ? 1 : 0.28)),
                       style: StrokeStyle(lineWidth: isCurrent ? 3 : 1.5,
                                          dash: event.kind == .decision ? [4, 3] : []))
      }

      for node in nodes {
        let center = point(for: node)
        let circle = CGRect(x: center.x - 13, y: center.y - 13, width: 26, height: 26)
        context.fill(Path(ellipseIn: circle),
                     with: .color(node.location == .array ? .blue : node.location == .buffer ? .teal : .indigo))
        context.draw(Text(node.label).font(.caption2.bold()).foregroundStyle(.white), at: center)
      }
    }
    .accessibilityHidden(true)
  }
}
