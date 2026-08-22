fun compSwap(arr: Array<Int>, a: Int, b: Int) {
  if (arr[a] > arr[b]) {
    val temp = arr[a]
    arr[a] = arr[b]
    arr[b] = temp
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  var maxVal = 1
  while (maxVal * 2 < n) {
    maxVal *= 2
  }

  var next = maxVal
  while (next > 0) {
    var i = 0
    while (i + 1 < n) {
      compSwap(arr, i, i + 1)
      i += 2
    }

    var j = maxVal
    while (j >= next && j > 1) {
      i = 1
      while (i + j - 1 < n) {
        compSwap(arr, i, i + j - 1)
        i += 2
      }
      j /= 2
    }

    next /= 2
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}