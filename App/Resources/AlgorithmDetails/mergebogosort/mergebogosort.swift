func sort(_ arr: inout [Int]) {
  var a = arr
  sortRange(&a, 0, a.count)
  arr = a
}

func sortRange(_ arr: inout [Int], _ start: Int, _ end: Int) {
  if start >= end - 1 {
    return
  }
  let mid = (start + end) / 2
  sortRange(&arr, start, mid)
  sortRange(&arr, mid, end)

  let saved = Array(arr[start..<end])

  func isSorted() -> Bool {
    for i in start..<(end - 1) {
      if arr[i] > arr[i + 1] {
        return false
      }
    }
    return true
  }

  while !isSorted() {
    let highPositions = Set(Array(0..<(end - start)).shuffled().prefix(end - mid))

    var low = 0
    var high = mid - start
    for offset in 0..<(end - start) {
      if highPositions.contains(offset) {
        arr[start + offset] = saved[high]
        high += 1
      } else {
        arr[start + offset] = saved[low]
        low += 1
      }
    }
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 14, 23]
sort(&array)
print(array)
