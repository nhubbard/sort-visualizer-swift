fun gravitySort(arr: Array<Int>) {
  val n = arr.size
  if (n == 0) return

  var minValue = arr[0]
  var maxValue = arr[0]
  for (i in 1 until n) {
    if (arr[i] < minValue) minValue = arr[i]
    if (arr[i] > maxValue) maxValue = arr[i]
  }
  val ySize = maxValue - minValue + 1

  val x = IntArray(n)
  val y = IntArray(ySize)

  for (i in 0 until n) {
    x[i] = arr[i] - minValue
    y[x[i]]++
  }

  for (i in ySize - 1 downTo 1) {
    y[i - 1] += y[i]
  }

  for (j in ySize - 1 downTo 0) {
    for (i in 0 until n) {
      val inc = (if (i >= n - y[j]) 1 else 0) - (if (x[i] >= j) 1 else 0)
      arr[i] += inc
    }
  }
}

fun sort(arr: Array<Int>) {
  gravitySort(arr)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
