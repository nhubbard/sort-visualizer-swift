func sort(_ arr: inout [Int]) {
  let n = arr.count
  var heapSize = n - 1

  func maxHeapify(_ i: Int) {
    let left = 3 * i + 1
    let mid = 3 * i + 2
    let right = 3 * i + 3
    var largest = i
    if left <= heapSize && arr[left] > arr[largest] { largest = left }
    if right <= heapSize && arr[right] > arr[largest] { largest = right }
    if mid <= heapSize && arr[mid] > arr[largest] { largest = mid }
    if largest != i {
      arr.swapAt(i, largest)
      maxHeapify(largest)
    }
  }

  for i in stride(from: n - 1, through: 0, by: -1) { maxHeapify(i) }
  for i in stride(from: n - 1, through: 0, by: -1) {
    arr.swapAt(0, i)
    heapSize -= 1
    maxHeapify(0)
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
