fun isSorted(arr: Array<Int>): Boolean =
  arr.toList().asSequence().zipWithNext { a, b ->
    a <= b
  }.all { it }

fun sort(arr: Array<Int>) {
  val n = arr.size
  while (!isSorted(arr)) {
    val i = (0 until n).random()
    val j = (0 until n).random()
    if ((i < j && arr[i] > arr[j]) || (i > j && arr[i] < arr[j])) {
      val t = arr[i]
      arr[i] = arr[j]
      arr[j] = t
    }
  }
}

fun main() {
  val array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
