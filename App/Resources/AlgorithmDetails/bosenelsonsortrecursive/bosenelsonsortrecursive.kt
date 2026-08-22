fun sort(arr: Array<Int>) {
  fun compSwap(start: Int, end: Int) {
    if (arr[start] > arr[end]) {
      val temp = arr[start]
      arr[start] = arr[end]
      arr[end] = temp
    }
  }

  fun merge(start1: Int, len1: Int, start2: Int, len2: Int) {
    if (len1 == 1 && len2 == 1) {
      compSwap(start1, start2)
    } else if (len1 == 1 && len2 == 2) {
      compSwap(start1, start2 + 1)
      compSwap(start1, start2)
    } else if (len1 == 2 && len2 == 1) {
      compSwap(start1, start2)
      compSwap(start1 + 1, start2)
    } else {
      val mid1 = len1 / 2
      val mid2 = if (len1 % 2 == 1) len2 / 2 else (len2 + 1) / 2
      merge(start1, mid1, start2, mid2)
      merge(start1 + mid1, len1 - mid1, start2 + mid2, len2 - mid2)
      merge(start1 + mid1, len1 - mid1, start2, mid2)
    }
  }

  fun boseNelson(start: Int, length: Int) {
    if (length > 1) {
      val mid = length / 2
      boseNelson(start, mid)
      boseNelson(start + mid, length - mid)
      merge(start, mid, start + mid, length - mid)
    }
  }

  boseNelson(0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}