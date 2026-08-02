fun mostSignificantBit(value: Int): Int {
  if (value == 0) return -1
  var bit = 0
  while ((value shr (bit + 1)) != 0) bit++
  return bit
}

fun partition(arr: Array<Int>, p: Int, r: Int, bit: Int): Int {
  var i = p - 1
  var j = r + 1
  while (true) {
    do {
      i++
    } while (i <= r && ((arr[i] shr bit) and 1) == 0)
    do {
      j--
    } while (j >= p && ((arr[j] shr bit) and 1) == 1)
    if (i < j) {
      val temp = arr[i]
      arr[i] = arr[j]
      arr[j] = temp
    } else {
      return j
    }
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  var maxValue = arr[0]
  for (i in 1 until n) {
    if (arr[i] > maxValue) maxValue = arr[i]
  }
  val bit = mostSignificantBit(maxValue)

  val tasks = ArrayDeque<Triple<Int, Int, Int>>()
  tasks.addLast(Triple(0, n - 1, bit))

  while (tasks.isNotEmpty()) {
    val (p, r, b) = tasks.removeFirst()
    if (p < r && b >= 0) {
      val q = partition(arr, p, r, b)
      tasks.addLast(Triple(p, q, b - 1))
      tasks.addLast(Triple(q + 1, r, b - 1))
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
