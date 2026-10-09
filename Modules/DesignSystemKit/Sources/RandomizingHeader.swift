import Foundation
import SwiftUI
import UIKit

/// Shuffles the title once, then puts its letters back in place with a paced Quick Sort.
/// Each letter has a unique destination index, including repeated letters and the space.
public struct RandomizingHeader: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 48
  @ScaledMetric(relativeTo: .largeTitle) private var lineHeight: CGFloat = 58

  private let text: String
  @State private var order: [Int] = []
  @State private var activeIndices: Set<Int> = []
  @State private var isSwapping = false
  @State private var movingSwap: SwapMotion?
  @State private var sortTask: Task<Void, Never>?

  private struct SwapMotion {
    let first: Int
    let second: Int
    let startedAt: Date
  }

  public init(text: String) {
    self.text = text
  }

  public var body: some View {
    Button(action: startSort) {
      ViewThatFits(in: .horizontal) {
        rows(maximumLettersPerRow: max(text.count, 1))
        rows(maximumLettersPerRow: 7)
        rows(maximumLettersPerRow: 5)
        rows(maximumLettersPerRow: 4)
        rows(maximumLettersPerRow: 3)
        rows(maximumLettersPerRow: 2)
      }
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
      .accessibilityHidden(true)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(text)
    .accessibilityHint(String(localized: "Shuffle once, then sort the title with Quick Sort", bundle: .module))
    .onAppear(perform: startSort)
    .onDisappear {
      sortTask?.cancel()
      order = Array(0..<text.count)
      activeIndices = []
      movingSwap = nil
    }
  }

  private var displayOrder: [Int] {
    order.isEmpty ? Array(0..<text.count) : order
  }

  private func rows(maximumLettersPerRow: Int) -> some View {
    let indices = displayOrder
    let letters = Array(text)
    let font = UIFont.systemFont(ofSize: titleSize, weight: .bold)
    let glyphWidths = letters.map {
      (String($0) as NSString).size(withAttributes: [.font: font]).width
    }
    let rowCount = (indices.count + maximumLettersPerRow - 1) / maximumLettersPerRow
    let width = glyphWidths.sorted(by: >).prefix(maximumLettersPerRow).reduce(0, +) + 2
    let height = CGFloat(rowCount) * lineHeight
    return TimelineView(.animation(minimumInterval: 1.0 / 30.0,
      paused: reduceMotion || movingSwap == nil)) { timeline in
      Canvas { context, _ in
        for (slot, letterID) in indices.enumerated() {
          let rendered = context.resolve(
            Text(String(letters[letterID]))
              .font(.system(size: titleSize, weight: .bold, design: .default))
              .foregroundColor(color(for: slot)))
          var position = point(for: slot, order: indices, glyphWidths: glyphWidths,
            width: width, maximumLettersPerRow: maximumLettersPerRow)
          if let movingSwap {
            var targetOrder = indices
            targetOrder.swapAt(movingSwap.first, movingSwap.second)
            let destination: Int
            if slot == movingSwap.first {
              destination = movingSwap.second
            } else if slot == movingSwap.second {
              destination = movingSwap.first
            } else {
              destination = slot
            }
            let end = point(for: destination, order: targetOrder, glyphWidths: glyphWidths,
              width: width, maximumLettersPerRow: maximumLettersPerRow)
            let elapsed = timeline.date.timeIntervalSince(movingSwap.startedAt)
            let fraction = min(max(elapsed / 0.28, 0), 1)
            let eased = fraction * fraction * (3 - 2 * fraction)
            position.x += (end.x - position.x) * eased
            position.y += (end.y - position.y) * eased
          }
          context.draw(rendered, at: position, anchor: .center)
        }
      }
      .frame(width: width, height: height)
    }
  }

  private func point(
    for slot: Int, order: [Int], glyphWidths: [CGFloat], width: CGFloat,
    maximumLettersPerRow: Int
  ) -> CGPoint {
    let row = slot / maximumLettersPerRow
    let rowStart = row * maximumLettersPerRow
    let rowEnd = min(rowStart + maximumLettersPerRow, order.count)
    let rowWidth = order[rowStart..<rowEnd].reduce(CGFloat.zero) {
      $0 + glyphWidths[$1]
    }
    let precedingWidth = order[rowStart..<slot].reduce(CGFloat.zero) {
      $0 + glyphWidths[$1]
    }
    return CGPoint(
      x: (width - rowWidth) / 2 + precedingWidth + glyphWidths[order[slot]] / 2,
      y: (CGFloat(row) + 0.5) * lineHeight)
  }

  private func color(for slot: Int) -> Color {
    guard activeIndices.contains(slot) else { return .primary }
    return isSwapping ? .green : .orange
  }

  private func startSort() {
    sortTask?.cancel()
    activeIndices = []
    isSwapping = false
    movingSwap = nil
    var shuffled = Array(0..<text.count).shuffled()
    if shuffled.count > 1, shuffled == shuffled.sorted() {
      shuffled.reverse()
    }
    order = shuffled
    let steps = HeaderQuickSort.steps(for: shuffled)
    sortTask = Task { @MainActor in
      do {
        try await Task.sleep(for: .milliseconds(400))
        for step in steps {
          try Task.checkCancellation()
          switch step {
          case .compare(let index, let pivot):
            activeIndices = [index, pivot]
            isSwapping = false
            try await Task.sleep(for: .milliseconds(90))
          case .swap(let first, let second):
            activeIndices = [first, second]
            isSwapping = true
            if reduceMotion {
              order.swapAt(first, second)
              try await Task.sleep(for: .milliseconds(280))
            } else {
              movingSwap = SwapMotion(first: first, second: second, startedAt: .now)
              try await Task.sleep(for: .milliseconds(280))
              try Task.checkCancellation()
              order.swapAt(first, second)
              movingSwap = nil
            }
          }
        }
        activeIndices = []
        isSwapping = false
      } catch {
        // A second tap or leaving Home cancels this run before another update.
      }
    }
  }
}

/// Lomuto Quick Sort over destination indices. The returned steps replay against the
/// shuffled order; comparing by destination restores the exact title, even with duplicate glyphs.
enum HeaderQuickSort {
  enum Step: Equatable {
    case compare(Int, Int)
    case swap(Int, Int)
  }

  static func steps(for input: [Int]) -> [Step] {
    guard input.count > 1 else { return [] }
    var values = input
    var steps: [Step] = []

    func sort(_ low: Int, _ high: Int) {
      guard low < high else { return }
      let pivot = values[high]
      var insertion = low
      for index in low..<high {
        steps.append(.compare(index, high))
        if values[index] < pivot {
          if insertion != index {
            values.swapAt(insertion, index)
            steps.append(.swap(insertion, index))
          }
          insertion += 1
        }
      }
      if insertion != high {
        values.swapAt(insertion, high)
        steps.append(.swap(insertion, high))
      }
      sort(low, insertion - 1)
      sort(insertion + 1, high)
    }

    sort(0, values.count - 1)
    return steps
  }
}
