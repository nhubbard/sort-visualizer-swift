fun classicGravitySort(arr: Array<Int>) {
  val n = arr.size
  if (n == 0) return

  var maxValue = arr[0]
  for (i in 1 until n) {
    if (arr[i] > maxValue) maxValue = arr[i]
  }

  val transpose = IntArray(maxValue)

  for (i in 0 until n) {
    val value = arr[i]
    for (j in 0 until value) {
      transpose[j]++
    }
  }

  for (i in 0 until n) {
    var total = 0
    for (j in 0 until maxValue) {
      if (transpose[j] > 0) total++
    }
    arr[n - i - 1] = total
    for (j in 0 until maxValue) {
      transpose[j]--
    }
  }
}

fun sort(arr: Array<Int>) {
  classicGravitySort(arr)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}