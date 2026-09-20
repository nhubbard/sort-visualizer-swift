fun siftDown(arr: Array<Int>, rootIn: Int, size: Int) {
  var root = rootIn
  while (true) {
    var largest = root
    val left = 2 * root + 1
    val right = left + 1
    if (left < size && arr[largest] < arr[left]) largest = left
    if (right < size && arr[largest] < arr[right]) largest = right
    if (largest == root) break
    arr[root] = arr[largest].also { arr[largest] = arr[root] }
    root = largest
  }
}

fun sort(arr: Array<Int>) {
  var n = arr.size
  for (i in (n / 2 - 1) downTo 0) {
    siftDown(arr, i, n)
  }
  for (i in (n - 1) downTo 1) {
    arr[0] = arr[i].also { arr[i] = arr[0] }
    siftDown(arr, 0, i)
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