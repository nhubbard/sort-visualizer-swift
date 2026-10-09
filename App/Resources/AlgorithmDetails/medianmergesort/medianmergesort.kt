fun sort(arr: Array<Int>) {
  val scratch = Array(arr.size) { 0 }

  fun mergeSort(start: Int, end: Int) {
    if (end - start < 2) return
    val middle = (start + end) / 2
    mergeSort(start, middle)
    mergeSort(middle, end)
    var left = start
    var right = middle
    var dest = start
    while (left < middle && right < end) {
      scratch[dest++] = if (arr[left] <= arr[right]) arr[left++] else arr[right++]
    }
    while (left < middle) scratch[dest++] = arr[left++]
    while (right < end) scratch[dest++] = arr[right++]
    for (i in start until end) arr[i] = scratch[i]
  }

  var start = 0
  var end = arr.size
  while (end - start > 16) {
    val samples = listOf(arr[start], arr[(start + end - 1) / 2], arr[end - 1]).sorted()
    val pivot = samples[1]
    var left = start
    var right = end - 1
    while (left <= right) {
      while (left <= right && arr[left] < pivot) left++
      while (left <= right && arr[right] > pivot) right--
      if (left <= right) {
        val value = arr[left]
        arr[left++] = arr[right]
        arr[right--] = value
      }
    }
    if (left == start || left == end) {
      mergeSort(start, end)
      return
    }
    if (left - start <= end - left) {
      mergeSort(start, left)
      start = left
    } else {
      mergeSort(left, end)
      end = left
    }
  }
  for (i in start + 1 until end) {
    val value = arr[i]
    var j = i
    while (j > start && arr[j - 1] > value) {
      arr[j] = arr[j - 1]
      j--
    }
    arr[j] = value
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
    10, 2, 95, 46, 21, 74, 6, 38,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
