fun push(arr: Array<Int>, low: Int, high: Int) {
  for (i in low..(high - 1)) {
    if (arr[i] > arr[i + 1]) {
      arr[i] = arr[i + 1].also { arr[i + 1] = arr[i] }
    }
  }
}

fun merge(arr: Array<Int>, low: Int, high: Int, mid: Int) {
  var i = low
  while (i <= mid) {
    if (arr[i] > arr[mid + 1]) {
      arr[i] = arr[mid + 1].also { arr[mid + 1] = arr[i] }
      push(arr, mid + 1, high)
    }
    i++
  }
}

fun mergeSort(arr: Array<Int>, low: Int, high: Int) {
  if (high - low == 0) {
    return
  } else if (high - low == 1) {
    if (arr[low] > arr[high]) {
      arr[low] = arr[high].also { arr[high] = arr[low] }
    }
  } else {
    val mid = (low + high) / 2
    mergeSort(arr, low, mid)
    mergeSort(arr, mid + 1, high)
    merge(arr, low, high, mid)
  }
}

fun sort(arr: Array<Int>) {
  if (arr.size >= 2) {
    mergeSort(arr, 0, arr.size - 1)
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
