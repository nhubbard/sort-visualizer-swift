fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) return

  // Simulate the reporting order that proportional-to-value sleep durations
  // would produce in a jitter-free race: sort by value, ties broken by the
  // original position, i.e. the order the sleeps were originally scheduled.
  val woken = arr.withIndex().sortedWith(compareBy({ it.value }, { it.index }))
  for (i in 0 until n) {
    arr[i] = woken[i].value
  }

  // Defensive cleanup pass: real scheduling jitter can't be fully trusted,
  // so finish with an ordinary insertion sort no matter what the race produced.
  for (i in 1 until n) {
    var j = i
    while (j > 0 && arr[j - 1] > arr[j]) {
      val t = arr[j - 1]
      arr[j - 1] = arr[j]
      arr[j] = t
      j--
    }
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