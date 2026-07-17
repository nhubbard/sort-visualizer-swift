import SwiftUI

/// Ported near-verbatim from `Legacy/Shared/Views/Utilities/RandomizingHeader.swift` — a header
/// that shuffles its own characters for a moment before settling, replayable by tapping it.
public struct RandomizingHeader: View {
  private let text: String
  @State private var currentText: String = ""

  public init(text: String) {
    self.text = text
  }

  public var body: some View {
    Text(currentText)
      .font(.system(size: 48, weight: .bold, design: .default))
      .multilineTextAlignment(.leading)
      .onTapGesture {
        animateHeader()
      }
      .onAppear {
        currentText = text
        animateHeader()
      }
  }

  private func animateHeader() {
    Task(priority: .high) {
      await doHeaderAnimation()
    }
  }

  private func doHeaderAnimation() async {
    for _ in 0..<48 {
      currentText = String(text.shuffled())
      try? await Task.sleep(nanoseconds: 50_000_000)
    }
    currentText = text
  }
}
