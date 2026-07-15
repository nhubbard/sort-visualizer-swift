fun sort(arr: Array<Int>, start: Int = 0, end: Int = arr.size) {
  if (start >= end - 1) {
    return
  }

  var pivot = start

  fun isPartitioned(): Boolean {
    for (i in start until pivot) {
      if (arr[i] > arr[pivot]) {
        return false
      }
    }
    for (i in (pivot + 1) until end) {
      if (arr[pivot] > arr[i]) {
        return false
      }
    }
    return true
  }

  while (!isPartitioned()) {
    for (i in start until end) {
      val j = i + (0 until (end - i)).random()
      if (pivot == i) {
        pivot = j
      } else if (pivot == j) {
        pivot = i
      }
      arr[i] = arr[j].also { arr[j] = arr[i] }
    }
  }

  sort(arr, start, pivot)
  sort(arr, pivot + 1, end)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
