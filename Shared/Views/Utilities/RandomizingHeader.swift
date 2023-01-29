//
//  RandomizingText.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

@preconcurrency import SwiftUI

@frozen public struct RandomizingHeader: View, Sendable {
  let text: String
  @State var currentText: String = ""
  
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
  
  /**
   * Start animating the header text with an asynchronous Task.
   * This function is simply a wrapper to make starting the animation easier in the two situations I use them in.
   */
  func animateHeader() {
    Task.init(priority: .high) {
      await doHeaderAnimation()
    }
  }
  
  /**
   * Randomized header animation type.
   */
  func doHeaderAnimation() async {
    for _ in 0..<48 {
      // Shuffle text
      currentText = String(text.shuffled())
      // Wait 50 ms
      try? await Task.sleep(nanoseconds: UInt64(50_000_000))
    }
    currentText = text
  }
}

struct RandomizingHeader_Previews: PreviewProvider {
  static var previews: some View {
    RandomizingHeader(text: "SORT VISUALIZER")
  }
}
