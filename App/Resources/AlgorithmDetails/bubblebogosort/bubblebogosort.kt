fun isSorted(arr: Array<Int>): Boolean =
  arr.toList().asSequence().zipWithNext { a, b ->
    a <= b
  }.all { it }

fun sort(arr: Array<Int>) {
  val n = arr.size
  while (!isSorted(arr)) {
    val index = (0..(n - 2)).random()
    if (arr[index] > arr[index + 1]) {
      arr[index] = arr[index + 1].also { arr[index + 1] = arr[index] }
    }
  }
}

fun main() {
  val array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
