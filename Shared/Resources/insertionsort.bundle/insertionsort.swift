func insertionSort(_ arr: inout [Int]) {
  let n = arr.count
  for i in 1..<n {
    let key = arr[i]
    var j = i - 1
    while j >= 0 && arr[j] > key {
      arr[j + 1] = arr[j]
      j = j - 1
    }
    arr[j + 1] = key
  }
}

var items: [Int] = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
insertionSort(&items)
print(items)