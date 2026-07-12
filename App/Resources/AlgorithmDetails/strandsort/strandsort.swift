func mergeTo(_ arr: inout [Int], _ subList: [Int], _ a: Int, _ m: Int, _ b: Int) {
  var a = a
  var m = m
  var i = 0
  let s = m - a
  while i < s && m < b {
    if subList[i] < arr[m] {
      arr[a] = subList[i]
      a += 1; i += 1
    } else {
      arr[a] = arr[m]
      a += 1; m += 1
    }
  }
  while i < s {
    arr[a] = subList[i]
    a += 1; i += 1
  }
}

func sort(_ arr: inout [Int]) {
  let n = arr.count
  if n < 2 { return }

  var subList = [Int](repeating: 0, count: n)

  var j = n
  var k = j
  while j > 0 {
    subList[0] = arr[0]
    k -= 1

    var i = 0
    var p = 0
    var m = 1
    while m < j {
      if arr[m] >= subList[i] {
        i += 1
        subList[i] = arr[m]
        k -= 1
      } else {
        arr[p] = arr[m]
        p += 1
      }
      m += 1
    }

    mergeTo(&arr, subList, k, j, n)
    j = k
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
