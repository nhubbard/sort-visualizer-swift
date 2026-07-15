func sort(_ arr: inout [Int], _ length: Int = -1) {
  let length = length < 0 ? arr.count : length
  if length == 1 {
    return
  }
  sort(&arr, length - 1)
  while arr[length - 2] > arr[length - 1] {
    var sub = Array(arr[0..<length])
    sub.shuffle()
    for i in 0..<length {
      arr[i] = sub[i]
    }
    sort(&arr, length - 1)
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 14, 23]
sort(&array)
print(array)
