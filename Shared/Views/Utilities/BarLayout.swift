//
//  BarLayout.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/15/25.
//

import SwiftUI

struct BarLayout: Layout {
  let items: [SortItem]

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    guard !items.isEmpty, subviews.count == items.count else { return }

    // ------------------------------------------------------------------
    // 1.  Pixel-snapped X grid
    // ------------------------------------------------------------------
    let count  = items.count
    let step   = Double(bounds.width) / Double(count)

    var edges: [CGFloat] = (0...count).map { i in
      CGFloat(round(Double(i) * step))
    }
    edges[edges.endIndex - 1] = bounds.width   // ← ensures full width

    // ------------------------------------------------------------------
    // 2.  Height math
    // ------------------------------------------------------------------
    let maxValue = CGFloat(items.map(\.value).max() ?? 1)

    // ------------------------------------------------------------------
    // 3.  Place each bar
    // ------------------------------------------------------------------
    for (index, subview) in subviews.enumerated() {
      let barWidth  = edges[index + 1] - edges[index]
      let barX      = bounds.minX + edges[index]

      let heightRatio = CGFloat(items[index].value) / maxValue
      let barHeight   = bounds.height * heightRatio
      let barY        = bounds.maxY

      subview.place(
        at: CGPoint(x: barX, y: barY),
        anchor: .bottomLeading,
        proposal: ProposedViewSize(width: barWidth, height: barHeight)
      )
    }
  }
}
