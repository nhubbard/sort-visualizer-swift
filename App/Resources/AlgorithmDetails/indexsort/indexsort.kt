fun sort(arr: Array<Int>) {
  val n = arr.size
  var minValue = arr[0]
  for (i in 1 until n) {
    if (arr[i] < minValue) minValue = arr[i]
  }

  for (i in 0 until n) {
    var cmpCount = 0
    while (arr[i] - minValue != i && cmpCount < n) {
      val j = arr[i] - minValue
      val temp = arr[i]
      arr[i] = arr[j]
      arr[j] = temp
      cmpCount++
    }
    if (cmpCount >= n - 1) break
  }
}

fun main() {
  var array = arrayOf<Int>(
    7, 3, 14, 0, 9, 5, 12, 1,
    15, 4, 10, 2, 13, 6, 11, 8,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
