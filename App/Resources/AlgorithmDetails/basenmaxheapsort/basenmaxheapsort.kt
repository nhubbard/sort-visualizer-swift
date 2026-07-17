const val BASE = 4

fun siftDown(arr: Array<Int>, node: Int, stop: Int) {
  val left = node * BASE + 1
  if (left >= stop) {
    return
  }
  var maxIndex = left
  var i = left + 1
  while (i < left + BASE && i < stop) {
    if (arr[maxIndex] < arr[i]) {
      maxIndex = i
    }
    i++
  }
  if (arr[node] < arr[maxIndex]) {
    arr[node] = arr[maxIndex].also { arr[maxIndex] = arr[node] }
    siftDown(arr, maxIndex, stop)
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  for (i in (n - 1) downTo 0) {
    siftDown(arr, i, n)
  }
  for (end in (n - 1) downTo 1) {
    arr[0] = arr[end].also { arr[end] = arr[0] }
    siftDown(arr, 0, end)
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
