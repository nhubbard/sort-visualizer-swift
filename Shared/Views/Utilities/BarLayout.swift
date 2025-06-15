//
//  BarLayout.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/15/25.
//

import SwiftUI

struct BarLayout: Layout {
  let items: [SortItem]

  // Accept whatever size the parent offers
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
    guard !items.isEmpty, items.count == subviews.count else { return }

    // ------------------------------------------------------------------
    // 1.  Pixel-snapped X grid
    // ------------------------------------------------------------------
    let count     = items.count
    let step      = Double(bounds.width) / Double(count)   // ideal width (may be fractional)

    // pre-compute the X coordinates of every bar’s left edge
    let edges: [CGFloat] = (0...count).map { i in
      CGFloat(round(Double(i) * step))                    // <-- ROUND here
    }
    // edges.count == count + 1;  edges[i+1] - edges[i] is the bar’s integer width

    // ------------------------------------------------------------------
    // 2.  Common Y/height maths
    // ------------------------------------------------------------------
    let maxValue = CGFloat(items.map(\.value).max() ?? 1)

    // ------------------------------------------------------------------
    // 3.  Place each sub-view
    // ------------------------------------------------------------------
    for (index, subview) in subviews.enumerated() {

      let barWidth  = edges[index + 1] - edges[index]      //  either ⌊step⌋ or ⌈step⌉
      let barX      = bounds.minX + edges[index]

      let heightRatio = CGFloat(items[index].value) / maxValue
      let barHeight   = bounds.height * heightRatio
      let barY        = bounds.maxY                        // bottom baseline

      subview.place(
        at: CGPoint(x: barX, y: barY),
        anchor: .bottomLeading,
        proposal: ProposedViewSize(width: barWidth, height: barHeight)
      )
    }
  }
}
