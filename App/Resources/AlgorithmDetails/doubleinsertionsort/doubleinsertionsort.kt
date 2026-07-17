fun doubleInsertionSort(arr: Array<Int>, start: Int, end: Int) {
  var left = start + (end - start) / 2 - 1
  var right = left + 1
  if (arr[left] > arr[right]) {
    arr[left] = arr[right].also { arr[right] = arr[left] }
  }
  left--
  right++

  while (left >= start && right < end) {
    if (arr[left] > arr[right]) {
      val leftItem = arr[right]
      val rightItem = arr[left]

      var pos = left + 1
      while (pos <= right && arr[pos] <= leftItem) {
        arr[pos - 1] = arr[pos]
        pos++
      }
      arr[pos - 1] = leftItem

      pos = right - 1
      while (pos >= left && arr[pos] >= rightItem) {
        arr[pos + 1] = arr[pos]
        pos--
      }
      arr[pos + 1] = rightItem
    } else {
      val leftItem = arr[left]
      val rightItem = arr[right]

      var pos = left + 1
      while (arr[pos] < leftItem) {
        arr[pos - 1] = arr[pos]
        pos++
      }
      arr[pos - 1] = leftItem

      pos = right - 1
      while (arr[pos] > rightItem) {
        arr[pos + 1] = arr[pos]
        pos--
      }
      arr[pos + 1] = rightItem
    }

    left--
    right++
  }

  if (right < end) {
    var pos = right - 1
    val current = arr[right]
    while (pos >= start && arr[pos] > current) {
      arr[pos + 1] = arr[pos]
      pos--
    }
    arr[pos + 1] = current
  }
}

fun sort(arr: Array<Int>) {
  if (arr.size > 1) {
    doubleInsertionSort(arr, 0, arr.size)
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
