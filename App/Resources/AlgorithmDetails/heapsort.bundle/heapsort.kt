fun heapify(arr: Array<Int>, n: Int, i: Int) {
  var largest = i
  var l = 2 * i + 1
  var r = 2 * i + 2
  if (l < n && arr[l] > arr[largest]) {
    largest = l
  }
  if (r < n && arr[r] > arr[largest]) {
    largest = r
  }
  if (largest != i) {
    arr[i] = arr[largest].also { arr[largest] = arr[i] }
    heapify(arr, n, largest)
  }
}

fun sort(arr: Array<Int>) {
  var n = arr.size
  for (i in (n / 2 - 1) downTo 0) {
    heapify(arr, n, i)
  }
  for (i in (n - 1) downTo 0) {
    arr[0] = arr[i].also { arr[i] = arr[0] }
    heapify(arr, i, 0)
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}