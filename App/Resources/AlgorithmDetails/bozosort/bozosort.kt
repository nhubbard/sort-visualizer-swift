import kotlin.random.Random

fun isSorted(arr: Array<Int>): Boolean =
  arr.toList().asSequence().zipWithNext { a, b ->
    a <= b
  }.all { it }

fun sort(arr: Array<Int>): Array<Int> {
  val n = arr.size
  while (!isSorted(arr)) {
    val i = Random.nextInt(n)
    val j = Random.nextInt(n)
    val t = arr[i]
    arr[i] = arr[j]
    arr[j] = t
  }
  return arr
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77)
  array = sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
