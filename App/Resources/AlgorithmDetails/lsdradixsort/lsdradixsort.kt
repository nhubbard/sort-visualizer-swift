fun sort(arr: Array<Int>) {
  val n = arr.size
  val maxValue = arr.maxOrNull() ?: 0
  val output = Array(n) { 0 }
  var divisor = 1
  while (true) {
    val counts = IntArray(4)
    for (value in arr) counts[(value / divisor) % 4]++
    for (digit in 1 until 4) counts[digit] += counts[digit - 1]
    for (i in n - 1 downTo 0) {
      val digit = (arr[i] / divisor) % 4
      counts[digit]--
      output[counts[digit]] = arr[i]
    }
    for (i in 0 until n) arr[i] = output[i]
    if (divisor > maxValue / 4) break
    divisor *= 4
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
