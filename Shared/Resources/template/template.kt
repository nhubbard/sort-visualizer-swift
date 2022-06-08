/* TODO: Insert Kotlin implementation of algorithm here. */

fun main() {
  var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
  quickSort(items, 0, items.size - 1)
  println("[%s]".format(items.joinToString(", ")))
}
