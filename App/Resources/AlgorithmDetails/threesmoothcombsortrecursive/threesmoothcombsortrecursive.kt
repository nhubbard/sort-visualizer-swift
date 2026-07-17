fun powerOfThree(arr: Array<Int>, pos: Int, gap: Int, end: Int) {
  if (pos + gap > end) {
    return
  }

  powerOfThree(arr, pos, gap * 3, end)
  powerOfThree(arr, pos + gap, gap * 3, end)
  powerOfThree(arr, pos + 2 * gap, gap * 3, end)

  var i = pos
  while (i + gap < end) {
    if (arr[i] > arr[i + gap]) {
      val t = arr[i]
      arr[i] = arr[i + gap]
      arr[i + gap] = t
    }
    i += gap
  }
}

fun recursiveComb(arr: Array<Int>, pos: Int, gap: Int, end: Int) {
  if (pos + gap > end) {
    return
  }

  recursiveComb(arr, pos, gap * 2, end)
  recursiveComb(arr, pos + gap, gap * 2, end)

  powerOfThree(arr, pos, gap, end)
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n > 1) {
    recursiveComb(arr, 0, 1, n)
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
