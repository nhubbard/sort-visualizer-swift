fun siftDown(arr: Array<Int>, root: Int, size: Int) {
  var root = root
  while (true) {
    var smallest = root
    val left = 2 * root + 1
    val right = 2 * root + 2
    if (left < size && arr[left] < arr[smallest]) {
      smallest = left
    }
    if (right < size && arr[right] < arr[smallest]) {
      smallest = right
    }
    if (smallest == root) {
      break
    }
    arr[root] = arr[smallest].also { arr[smallest] = arr[root] }
    root = smallest
  }
}

fun heapify(arr: Array<Int>) {
  for (i in (arr.size / 2 - 1) downTo 0) {
    siftDown(arr, i, arr.size)
  }
}

fun reverse(arr: Array<Int>) {
  var low = 0
  var high = arr.size - 1
  while (low < high) {
    arr[low] = arr[high].also { arr[high] = arr[low] }
    low++
    high--
  }
}

fun sort(arr: Array<Int>) {
  heapify(arr)
  for (end in (arr.size - 1) downTo 1) {
    arr[0] = arr[end].also { arr[end] = arr[0] }
    siftDown(arr, 0, end)
  }
  reverse(arr)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
