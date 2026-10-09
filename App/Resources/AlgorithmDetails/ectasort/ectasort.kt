fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  var run = n
  while (run >= 32) run = (run + 1) / 2

  fun insertion(start: Int, end: Int) {
    for (i in start + 1 until end) {
      val value = arr[i]
      var low = start
      var high = i
      while (low < high) {
        val middle = low + (high - low) / 2
        if (arr[middle] > value) high = middle else low = middle + 1
      }
      for (j in i downTo low + 1) arr[j] = arr[j - 1]
      arr[low] = value
    }
  }

  if (n <= 32) {
    insertion(0, n)
    return
  }
  val half = n / 2
  var buffer = arr.sliceArray(half until 2 * half)

  fun mergeBackward(start: Int, middle: Int, end: Int, workspace: Int) {
    val count = end - middle
    for (offset in 0 until count) arr[workspace + offset] = arr[middle + offset]
    var left = middle - 1
    var right = workspace + count - 1
    var output = end - 1
    while (left >= start && right >= workspace) {
      if (arr[left] > arr[right]) arr[output--] = arr[left--]
      else arr[output--] = arr[right--]
    }
    while (right >= workspace) arr[output--] = arr[right--]
  }

  fun sortSegment(start: Int, end: Int, workspace: Int) {
    var lower = start
    while (lower < end) {
      insertion(lower, minOf(lower + run, end))
      lower += run
    }
    var width = run
    while (width < end - start) {
      lower = start
      while (lower < end) {
        val middle = minOf(lower + width, end)
        val upper = minOf(lower + 2 * width, end)
        if (middle < upper) mergeBackward(lower, middle, upper, workspace)
        lower += 2 * width
      }
      width *= 2
    }
  }

  sortSegment(0, half, half)
  for (i in 0 until half) arr[half + i] = buffer[i]
  buffer = arr.sliceArray(0 until half)
  sortSegment(half, n, 0)
  var left = 0
  var right = half
  var output = 0
  while (left < half && right < n) {
    if (buffer[left] <= arr[right]) arr[output++] = buffer[left++]
    else arr[output++] = arr[right++]
  }
  while (left < half) arr[output++] = buffer[left++]
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
