let threshold = 32

func insertionSort(_ arr: inout [Int], _ start: Int, _ end: Int) {
  var i = start + 1
  while i < end {
    var j = i
    while j > start && arr[j] < arr[j - 1] {
      arr.swapAt(j - 1, j)
      j -= 1
    }
    i += 1
  }
}

func merge(_ arr: inout [Int], _ start: Int, _ mid: Int, _ end: Int) {
  var low = start
  var high = mid
  var merged: [Int] = []
  while low < mid && high < end {
    if arr[high] < arr[low] {
      merged.append(arr[high])
      high += 1
    } else {
      merged.append(arr[low])
      low += 1
    }
  }
  while low < mid {
    merged.append(arr[low])
    low += 1
  }
  while high < end {
    merged.append(arr[high])
    high += 1
  }
  for i in 0..<merged.count {
    arr[start + i] = merged[i]
  }
}

func mergeSort(_ arr: inout [Int], _ start: Int, _ end: Int) {
  if end - start <= threshold {
    insertionSort(&arr, start, end)
    return
  }
  let mid = start + (end - start) / 2
  mergeSort(&arr, start, mid)
  mergeSort(&arr, mid, end)
  merge(&arr, start, mid, end)
}

func sort(_ arr: inout [Int]) {
  let n = arr.count
  if n < 2 { return }
  mergeSort(&arr, 0, n)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
