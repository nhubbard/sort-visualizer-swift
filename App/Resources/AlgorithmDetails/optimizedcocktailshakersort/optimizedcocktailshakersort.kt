fun sort(arr: Array<Int>) {
  var start = 0
  var end = arr.size - 1
  while (start < end) {
    var consecSorted = 1
    for (i in start until end) {
      if (arr[i] > arr[i + 1]) {
        arr[i] = arr[i + 1].also { arr[i + 1] = arr[i] }
        consecSorted = 1
      } else {
        consecSorted++
      }
    }
    end -= consecSorted

    consecSorted = 1
    var j = end
    while (j > start) {
      if (arr[j - 1] > arr[j]) {
        arr[j - 1] = arr[j].also { arr[j] = arr[j - 1] }
        consecSorted = 1
      } else {
        consecSorted++
      }
      j--
    }
    start += consecSorted
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
