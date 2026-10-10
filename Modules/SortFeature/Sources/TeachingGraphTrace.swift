import Foundation
import SortEngineKit

/// A read-only teaching stream derived from the tape that ReplayEngine actually plays. The
/// positions therefore remain correct for imported tapes and fast-playback-compacted tapes.
/// The optional annotation sidecar supplies authored decision explanations. Older pilot tapes
/// still use operation-derived text for Quick Sort and Merge Sort.
struct TeachingGraphTrace {
  enum Variant: Equatable {
    case quickSort
    case mergeSort
    case annotated
  }

  struct Node: Hashable, Comparable {
    enum Location: Int, Hashable {
      case array
      case buffer
      case value
    }

    let location: Location
    let index: Int
    let handle: Int

    static func array(_ index: Int) -> Node {
      Node(location: .array, index: index, handle: 0)
    }

    static func buffer(_ handle: Int, _ index: Int) -> Node {
      Node(location: .buffer, index: index, handle: handle)
    }

    static func value(_ value: Int) -> Node {
      Node(location: .value, index: value, handle: 0)
    }

    static func < (lhs: Node, rhs: Node) -> Bool {
      if lhs.location != rhs.location { return lhs.location.rawValue < rhs.location.rawValue }
      if lhs.handle != rhs.handle { return lhs.handle < rhs.handle }
      return lhs.index < rhs.index
    }

    var label: String {
      switch location {
      case .array: "\(index + 1)"
      case .buffer: "B\(index + 1)"
      case .value: "V\(index)"
      }
    }
  }

  struct Event: Equatable {
    enum Kind: Equatable {
      case decision
      case movement
      case pivotPlacement
      case bufferWrite
      case mergeWrite
    }

    /// ReplayEngine.stepIndex after this operation has been applied.
    let step: Int
    let source: Node
    let target: Node
    let kind: Kind
    let explanation: String
  }

  struct Snapshot {
    let events: [Event]
    let current: Event?
    let currentNumber: Int
    let nodeCount: Int

    var nodes: [Node] {
      Array(Set(events.flatMap { [$0.source, $0.target] })).sorted()
    }
  }

  static let maximumVisibleEvents = 10
  static let maximumVisibleNodes = 12

  let variant: Variant
  let sortStartIndex: Int
  let events: [Event]

  init?(tape: Tape) {
    switch tape.header.algorithmID {
    case "quicksort": variant = .quickSort
    case "mergesort": variant = .mergeSort
    default:
      guard !tape.teachingAnnotations.isEmpty else { return nil }
      variant = .annotated
    }
    let startIndex = tape.header.sortStartIndex
    sortStartIndex = startIndex

    var built: [Event] = []
    built.reserveCapacity(tape.operations.count / 3)
    var pivot: Int?
    var sources: [Int] = []
    var nextSource = 0
    var bufferHandle: Int?

    for (index, operation) in tape.operations.enumerated() where index >= startIndex {
      let step = index + 1
      switch variant {
      case .annotated:
        break
      case .quickSort:
        switch operation {
        case .compare(let first, let second):
          pivot = first
          // Quick Sort probes the pivot against itself when a partition begins. That probe
          // establishes loop state, but it does not explain a decision between positions.
          guard first != second else { break }
          built.append(Event(
            step: step, source: .array(first), target: .array(second), kind: .decision,
            explanation: String(localized: "Compare pivot at position \(first + 1) with position \(second + 1).", bundle: .module)))
        case .swap(let first, let second):
          if first == pivot {
            built.append(Event(
              step: step, source: .array(first), target: .array(second),
              kind: .pivotPlacement,
              explanation: first == second
                ? String(localized: "Keep the pivot at position \(first + 1); this partition is complete.", bundle: .module)
                : String(localized: "Place the pivot from position \(first + 1) at position \(second + 1).", bundle: .module)))
            pivot = nil
          } else {
            built.append(Event(
              step: step, source: .array(first), target: .array(second), kind: .movement,
              explanation: String(localized: "Swap positions \(first + 1) and \(second + 1) within the partition.", bundle: .module)))
          }
        default: break
        }
      case .mergeSort:
        switch operation {
        case .auxCreate(let handle, _):
          bufferHandle = handle
        case .compare(let first, let second):
          built.append(Event(
            step: step, source: .array(first), target: .array(second), kind: .decision,
            explanation: String(localized: "Compare positions \(first + 1) and \(second + 1) for the merge.", bundle: .module)))
        case .readValue(let source):
          sources.append(source)
        case .auxWrite(let handle, let destination, let value):
          guard nextSource < sources.count else { break }
          let source = sources[nextSource]
          nextSource += 1
          bufferHandle = handle
          built.append(Event(
            step: step, source: .array(source), target: .buffer(handle, destination),
            kind: .bufferWrite,
            explanation: String(localized: "Move value \(value) from position \(source + 1) into buffer position \(destination + 1).", bundle: .module)))
        case .setValue(let destination, let value):
          guard let bufferHandle else { break }
          built.append(Event(
            step: step, source: .buffer(bufferHandle, destination), target: .array(destination),
            kind: .mergeWrite,
            explanation: String(localized: "Write value \(value) from buffer position \(destination + 1) to array position \(destination + 1).", bundle: .module)))
        default: break
        }
      }
    }
    if variant == .annotated {
      built = tape.teachingAnnotations.compactMap { annotation in
        guard annotation.operationIndex >= startIndex,
          tape.operations.indices.contains(annotation.operationIndex),
          let endpoints = Self.endpoints(for: annotation) else { return nil }
        let operation = tape.operations[annotation.operationIndex]
        let kind: Event.Kind
        switch operation {
        case .compare, .compareValue, .compareValues: kind = .decision
        case .auxWrite: kind = .bufferWrite
        case .setValue, .swap, .reversal: kind = .movement
        default: kind = .decision
        }
        return Event(step: annotation.operationIndex + 1,
          source: endpoints.0, target: endpoints.1, kind: kind,
          explanation: Self.explanation(for: annotation)
            ?? Self.fallbackExplanation(for: annotation))
      }.sorted { $0.step < $1.step }
      events = built
      return
    }
    let decisions = Dictionary(
      tape.teachingAnnotations.map { ($0.operationIndex + 1, $0) },
      uniquingKeysWith: { _, latest in latest })
    events = built.map { event in
      guard event.kind == .decision,
        let annotation = decisions[event.step],
        let explanation = Self.explanation(for: annotation) else { return event }
      return Event(step: event.step, source: event.source, target: event.target,
        kind: event.kind, explanation: explanation)
    }
  }

  private static func explanation(for annotation: TeachingAnnotation) -> String? {
    guard annotation.definitionVersion == 1 else { return nil }
    switch annotation.explanationKey {
    case "quick.pivotSide":
      guard let pivot = annotation.roles["pivot"]?.arrayIndex,
        let candidate = annotation.roles["candidate"]?.arrayIndex else {
        return annotation.explanation
      }
      switch annotation.outcome {
      case "advance":
        return String(localized: "Position \(candidate + 1) is on the pivot's left side; advance the scan from pivot \(pivot + 1).", bundle: .module)
      case "oppositeSide":
        return String(localized: "Position \(candidate + 1) belongs on the other side of pivot \(pivot + 1); stop this scan.", bundle: .module)
      case "boundary":
        return String(localized: "The scan reached the partition boundary at position \(candidate + 1).", bundle: .module)
      case "retreat":
        return String(localized: "Position \(candidate + 1) is beyond pivot \(pivot + 1); move the right scan back.", bundle: .module)
      case "stop":
        return String(localized: "Position \(candidate + 1) is no greater than pivot \(pivot + 1); stop the right scan.", bundle: .module)
      default: break
      }
    case "merge.runChoice":
      guard let left = annotation.roles["left"]?.arrayIndex,
        let right = annotation.roles["right"]?.arrayIndex else {
        return annotation.explanation
      }
      switch annotation.outcome {
      case "left":
        return String(localized: "Choose position \(left + 1) from the left run; its value is no greater than position \(right + 1).", bundle: .module)
      case "right":
        return String(localized: "Choose position \(right + 1) from the right run; its value is smaller than position \(left + 1).", bundle: .module)
      default: break
      }
    default: break
    }
    return annotation.explanation?.isEmpty == false ? annotation.explanation : nil
  }

  private static func endpoints(for annotation: TeachingAnnotation) -> (Node, Node)? {
    let preferred = ["pivot", "left", "source", "current", "candidate", "right", "target", "destination"]
    let keys = preferred.filter { annotation.roles[$0] != nil }
      + annotation.roles.keys.filter { !preferred.contains($0) }.sorted()
    let nodes = keys.flatMap { key -> [Node] in
      switch annotation.roles[key] {
      case .arrayIndex(let index): return [.array(index)]
      case .auxiliaryIndex(let handle, let index): return [.buffer(handle, index)]
      case .value(let value): return [.value(value)]
      case .range(let range):
        guard !range.isEmpty else { return [] }
        return [.array(range.lowerBound), .array(range.upperBound - 1)]
      default: return []
      }
    }
    guard let first = nodes.first else { return nil }
    return (first, nodes.dropFirst().first ?? first)
  }

  private static func fallbackExplanation(for annotation: TeachingAnnotation) -> String {
    let stage = annotation.stageID.replacingOccurrences(of: ".", with: " ")
    let outcome = annotation.outcome.replacingOccurrences(of: ".", with: " ")
    return "\(stage): \(outcome)."
  }

  /// Index of the last event applied at `step`, or nil before the first graph event.
  func eventIndex(at step: Int) -> Int? {
    var low = 0
    var high = events.count
    while low < high {
      let mid = low + (high - low) / 2
      if events[mid].step <= step { low = mid + 1 } else { high = mid }
    }
    return low == 0 ? nil : low - 1
  }

  func previousStep(before step: Int) -> Int? {
    guard let index = eventIndex(at: step - 1) else { return nil }
    return events[index].step
  }

  func nextStep(after step: Int) -> Int? {
    let next = (eventIndex(at: step) ?? -1) + 1
    return next < events.count ? events[next].step : nil
  }

  func snapshot(at step: Int) -> Snapshot {
    guard let index = eventIndex(at: step) else {
      return Snapshot(events: [], current: nil, currentNumber: 0, nodeCount: 0)
    }
    var selected: [Event] = []
    var nodes: Set<Node> = []
    for candidate in events[0...index].reversed() {
      let expanded = nodes.union([candidate.source, candidate.target])
      if expanded.count > Self.maximumVisibleNodes { break }
      selected.append(candidate)
      nodes = expanded
      if selected.count == Self.maximumVisibleEvents { break }
    }
    return Snapshot(
      events: selected.reversed(), current: events[index], currentNumber: index + 1,
      nodeCount: nodes.count)
  }
}
