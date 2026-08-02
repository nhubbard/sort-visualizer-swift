fun sort(arr: Array<Int>): Array<Int> {
  val n = arr.size
  val max = arr.max()

  val counts = IntArray(max + 1)
  for (value in arr) {
    counts[value]++
  }
  for (i in 1..max) {
    counts[i] += counts[i - 1]
  }

  val output = arrayOfNulls<Int>(n)
  for (i in n - 1 downTo 0) {
    counts[arr[i]]--
    output[counts[arr[i]]] = arr[i]
  }

  return Array(n) { output[it]!! }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  array = sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
