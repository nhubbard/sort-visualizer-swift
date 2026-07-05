//
//  TouchBarSlider.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/16/25.
//

import SwiftUI

/// A capsule button that expands to reveal a slider, Touch-Bar style.
struct TouchBarSlider<Label: View>: View {
  // PUBLIC
  @Binding var value: Float
  let range: ClosedRange<Float>
  let step: Float?
  let formatter: (Float) -> String
  let valueLabel: () -> Label   // e.g. Label("Array Size", systemImage: …)
  var isEnabled: Bool = true

  // PRIVATE
  @State private var expanded = false
  @Namespace private var ns

  var body: some View {
    Button {
      withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() }
    } label: {
      HStack(spacing: 8) {
        // ──── static label / icon ────
        valueLabel()

        // ──── slider + live value when expanded ────
        if expanded {
          Slider(
            value: Binding(
              get: { Double(value) },
              set: { value = Float($0) }
            ),
            in: Double(range.lowerBound)...Double(range.upperBound),
            step: step.map(Double.init) ?? 0
          )
          .frame(width: expanded ? 160 : 0)            // width animates
          .opacity(expanded ? 1 : 0)                   // fade matches width
          .animation(.easeInOut(duration: 0.25), value: expanded)
          .matchedGeometryEffect(id: "slider", in: ns)

          Text(formatter(value))
            .font(.footnote.monospacedDigit())
            .foregroundColor(.accentColor)
            .opacity(expanded ? 1 : 0)
            .offset(x: expanded ? 0 : -4)             // small slide-in
            .animation(
              .easeInOut(duration: 0.15).delay(0.25),
              value: expanded
            )
        }
      }
      .animation(.easeInOut(duration: 0.25), value: expanded)
    }
    .controlSize(.large)
    .glassEffect()
    .disabled(!isEnabled)
  }
}
