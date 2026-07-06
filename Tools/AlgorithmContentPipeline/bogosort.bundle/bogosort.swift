func sort(_ arr: inout [Int]) {
  while (arr != arr.sorted()) {
    arr.shuffle()
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23]
sort(&array)
print(array)
