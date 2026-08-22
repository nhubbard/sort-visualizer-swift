import kotlin.math.sqrt

fun triangularRoot(val_: Int): Int = ((sqrt((8 * val_ + 1).toDouble())).toInt() - 1) / 2

fun siftDown(array: IntArray, rootIn: Int, size: Int) {
  var root = rootIn
  while (true) {
    val row = triangularRoot(root)
    val left = root + row + 1
    if (left >= size) break
    val right = left + 1
    var largest = root
    if (array[largest] < array[left]) largest = left
    if (right < size && array[largest] < array[right]) largest = right
    if (largest == root) break
    val temp = array[root]
    array[root] = array[largest]
    array[largest] = temp
    root = largest
  }
}

fun heapify(array: IntArray, length: Int) {
  for (i in length - 1 downTo 0) {
    siftDown(array, i, length)
  }
}

fun sort(array: IntArray) {
  val n = array.size
  if (n <= 1) return
  heapify(array, n)
  for (i in 1 until n - 1) {
    val temp = array[0]
    array[0] = array[n - i]
    array[n - i] = temp
    siftDown(array, 0, n - i)
  }
  if (array[0] > array[1]) {
    val temp = array[0]
    array[0] = array[1]
    array[1] = temp
  }
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println(array.joinToString(", ", "[", "]"))
}
