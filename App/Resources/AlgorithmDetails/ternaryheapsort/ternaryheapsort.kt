fun sort(arr: Array<Int>) {
  val n = arr.size
  var heapSize = n - 1

  fun maxHeapify(i: Int) {
    val left = 3 * i + 1
    val mid = 3 * i + 2
    val right = 3 * i + 3
    var largest = i
    if (left <= heapSize && arr[left] > arr[largest]) {
      largest = left
    }
    if (right <= heapSize && arr[right] > arr[largest]) {
      largest = right
    }
    if (mid <= heapSize && arr[mid] > arr[largest]) {
      largest = mid
    }
    if (largest != i) {
      arr[i] = arr[largest].also { arr[largest] = arr[i] }
      maxHeapify(largest)
    }
  }

  for (i in n - 1 downTo 0) {
    maxHeapify(i)
  }
  for (i in n - 1 downTo 0) {
    arr[0] = arr[i].also { arr[i] = arr[0] }
    heapSize -= 1
    maxHeapify(0)
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
