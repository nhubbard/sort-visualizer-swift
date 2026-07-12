func snuffleSort(
  _ arr: inout [Int],
  _ start: Int,
  _ stop: Int
) {
  if stop - start + 1 >= 2 {
    if arr[start] > arr[stop] {
      arr.swapAt(start, stop)
    }
    if stop - start + 1 >= 3 {
      let mid = (stop - start) / 2 + start
      let iterations = (stop - start + 1) / 2
      for _ in 0..<iterations {
        snuffleSort(&arr, start, mid)
        snuffleSort(&arr, mid, stop)
      }
    }
  }
}

func sort(_ array: inout [Int]) {
  snuffleSort(&array, 0, array.count - 1)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23]
sort(&array)
print(array)
