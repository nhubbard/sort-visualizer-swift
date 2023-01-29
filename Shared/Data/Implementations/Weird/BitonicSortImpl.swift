//
//  BitonicSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  @MainActor
  @inlinable
  func bitonicSort() async {
    guard await enforceRunning() else { return }
    /// This code may look awful, and that's because it is, but all it does is round the array size to the nearest power of two.
    if ![16, 32, 64, 128, 256, 512, 1024, 2048, 4096].contains(Int(arraySizeBacking)) {
      /// The original value.
      let original = arraySizeBacking
      /// The original value as a double.
      let currDouble = Double(original)
      /// Take the base-2/binary logarithm of the double value.
      let logged = log2(currDouble)
      /// Get the ceiling of this base 2 logarithm.
      let ceiling = ceil(logged)
      /// Convert the ceiling value to an integer.
      let intCeiling = Int(ceiling)
      /// Get the value of 2^(intCeiling).
      let base2 = pow(Decimal(2), intCeiling)
      /// Convert it to an NSDecimalNumber.
      let nsDecimal = NSDecimalNumber(decimal: base2)
      /// Truncate the number to an integer.
      let truncated = Int(truncating: nsDecimal)
      /// Convert it to a Float for the Slider backing value.
      let asFloat = Float(truncated)
      /// Set the value.
      arraySizeBacking = asFloat
      /// Create a new array with the new size.
      data = await ShuffleMethod.create(maximum: Int(arraySizeBacking))
    }
    let n = data.count
    var k = 2
    while k <= n {
      guard await enforceRunning() else { return }
      var j = Int(floor(Double(k / 2)))
      while j > 0 {
        guard await enforceRunning() else { return }
        for i in 0..<n {
          guard await enforceRunning() else { return }
          let l = i ^ j
          if l > i {
            let comp = await compare(i, l)
            if (i & k) == 0 && comp || (i & k) != 0 && (!comp) {
              await swap(i, l)
            }
          }
        }
        j = Int(floor(Double(j / 2)))
      }
      k *= 2
    }
  }
}
