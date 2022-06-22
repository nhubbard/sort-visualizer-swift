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
    guard await enforceRunning() else {
      return
    }
    if ![16, 32, 64, 128, 256, 512].contains(Int(arraySizeBacking)) {
      let original = arraySizeBacking
      let currDouble = Double(original)
      let logged = log2(currDouble)
      let ceiling = ceil(logged)
      let intCeiling = Int(ceiling)
      let base2 = pow(Decimal(2), intCeiling)
      let nsDecimal = NSDecimalNumber(decimal: base2)
      let truncated = Int(truncating: nsDecimal)
      let asFloat = Float(truncated)
      arraySizeBacking = asFloat
      data = await SortItem.sequenceOf(numItems: Int(arraySizeBacking))
    }
    let n = data.count
    var k = 2
    while k <= n {
      guard await enforceRunning() else {
        return
      }
      var j = Int(floor(Double(k / 2)))
      while j > 0 {
        guard await enforceRunning() else {
          return
        }
        for i in 0..<n {
          guard await enforceRunning() else {
            return
          }
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
