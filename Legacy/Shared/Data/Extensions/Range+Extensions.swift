//
//  Range+Extensions.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/3/22.
//

import Foundation

extension ClosedRange where Bound == Float {
  public var min: Float {
    Swift.min(lowerBound, upperBound)
  }

  public var max: Float {
    Swift.max(lowerBound, upperBound)
  }
}

@inlinable
func floatRatio(x: Float, oldRange: ClosedRange<Float>, newRange: ClosedRange<Float>) -> Float {
  // Complete a range check.
  assert(oldRange.lowerBound != oldRange.upperBound, "Old range bounds cannot be equal!")
  assert(newRange.lowerBound != newRange.upperBound, "New range bounds cannot be equal!")
  // Calculate new range.
  return (x - oldRange.min) * (newRange.max - newRange.min) / (oldRange.max - oldRange.min) + newRange.min
}
