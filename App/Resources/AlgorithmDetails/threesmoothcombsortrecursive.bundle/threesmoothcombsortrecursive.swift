import Foundation

func powerOfThree(_ arr: inout [Int], _ pos: Int, _ gap: Int, _ end: Int) {
  guard pos + gap <= end else { return }

  powerOfThree(&arr, pos, gap * 3, end)
  powerOfThree(&arr, pos + gap, gap * 3, end)
  powerOfThree(&arr, pos + 2 * gap, gap * 3, end)

  var i = pos
  while i + gap < end {
    if arr[i] > arr[i + gap] {
      arr.swapAt(i, i + gap)
    }
    i += gap
  }
}

func recursiveComb(_ arr: inout [Int], _ pos: Int, _ gap: Int, _ end: Int) {
  guard pos + gap <= end else { return }

  recursiveComb(&arr, pos, gap * 2, end)
  recursiveComb(&arr, pos + gap, gap * 2, end)

  powerOfThree(&arr, pos, gap, end)
}

func sort(_ arr: inout [Int]) {
  let n = arr.count
  if n > 1 {
    recursiveComb(&arr, 0, 1, n)
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
