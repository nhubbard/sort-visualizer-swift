fun isSorted(arr: Array<Int>): Boolean =
  arr.toList().asSequence().zipWithNext { a, b ->
    a <= b
  }.all { it }

fun sort(arr: Array<Int>): Array<Int> {
  var copy = arr
  while (!isSorted(arr)) copy.shuffle()
  return copy
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23)
  array = sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
