fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n == 0) return

  val minValue = arr.min()
  val maxValue = arr.max()
  val auxLength = maxValue - minValue
  val aux = IntArray(auxLength)

  fun transferTo(index: Int) {
    var pointer = 0
    while (arr[index] > minValue) {
      arr[index]--
      aux[pointer]++
      pointer++
    }
  }

  fun transferFrom(index: Int) {
    var pointer = 0
    while (pointer < auxLength && aux[pointer] != 0) {
      arr[index]++
      aux[pointer]--
      pointer++
    }
  }

  for (i in 0 until n) {
    transferTo(i)
  }
  for (i in n - 1 downTo 0) {
    transferFrom(i)
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
