const val THRESHOLD = 32

fun insertionSort(arr: Array<Int>, start: Int, end: Int) {
  for (i in start + 1 until end) {
    var j = i
    while (j > start && arr[j] < arr[j - 1]) {
      val temp = arr[j - 1]
      arr[j - 1] = arr[j]
      arr[j] = temp
      j--
    }
  }
}

fun merge(arr: Array<Int>, start: Int, mid: Int, end: Int) {
  var low = start
  var high = mid
  val merged = mutableListOf<Int>()
  while (low < mid && high < end) {
    if (arr[high] < arr[low]) {
      merged.add(arr[high])
      high++
    } else {
      merged.add(arr[low])
      low++
    }
  }
  while (low < mid) {
    merged.add(arr[low])
    low++
  }
  while (high < end) {
    merged.add(arr[high])
    high++
  }
  for (i in merged.indices) {
    arr[start + i] = merged[i]
  }
}

fun mergeSort(arr: Array<Int>, start: Int, end: Int) {
  if (end - start <= THRESHOLD) {
    insertionSort(arr, start, end)
    return
  }
  val mid = start + (end - start) / 2
  mergeSort(arr, start, mid)
  mergeSort(arr, mid, end)
  merge(arr, start, mid, end)
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  mergeSort(arr, 0, n)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
