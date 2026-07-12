import Foundation

func intPow(_ base: Int, _ exponent: Int) -> Int {
  var result = 1
  for _ in 0..<exponent {
    result *= base
  }
  return result
}

func getDigit(_ value: Int, _ power: Int, _ radix: Int) -> Int {
  (value / intPow(radix, power)) % radix
}

func radixMSD(_ array: inout [Int], _ low: Int, _ high: Int, _ radix: Int, _ power: Int) {
  if low >= high || power < 0 {
    return
  }

  var buckets = [[Int]](repeating: [], count: radix)
  for i in low..<high {
    buckets[getDigit(array[i], power, radix)].append(array[i])
  }

  var index = low
  for bucket in buckets {
    for value in bucket {
      array[index] = value
      index += 1
    }
  }

  var start = low
  for bucket in buckets {
    radixMSD(&array, start, start + bucket.count, radix, power - 1)
    start += bucket.count
  }
}

func sort(_ array: inout [Int]) {
  if array.count <= 1 {
    return
  }
  let radix = 4
  let maxValue = array.max() ?? 0
  var highestPower = 0
  var probe = radix
  while probe <= maxValue {
    highestPower += 1
    probe *= radix
  }
  radixMSD(&array, 0, array.count, radix, highestPower)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
