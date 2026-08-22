fun sort(arr: Array<Int>): Array<Int> {
  val n = arr.size
  val min = arr.min()
  val max = arr.max()
  val size = max - min + 1

  val holes = IntArray(size)
  for (value in arr) {
    holes[value - min]++
  }

  val output = arrayOfNulls<Int>(n)
  var j = 0
  for (count in 0 until size) {
    while (holes[count] > 0) {
      holes[count]--
      output[j] = count + min
      j++
    }
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
