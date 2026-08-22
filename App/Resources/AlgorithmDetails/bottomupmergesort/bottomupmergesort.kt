fun merge(arr: Array<Int>, low: Int, mid: Int, high: Int) {
  val left = arr.copyOfRange(low, mid)
  val right = arr.copyOfRange(mid, high)
  var i = 0
  var j = 0
  var k = low
  while (i < left.size && j < right.size) {
    if (left[i] <= right[j]) {
      arr[k] = left[i]
      i++
    } else {
      arr[k] = right[j]
      j++
    }
    k++
  }
  while (i < left.size) {
    arr[k] = left[i]
    i++
    k++
  }
  while (j < right.size) {
    arr[k] = right[j]
    j++
    k++
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  var width = 1
  while (width < n) {
    var low = 0
    while (low < n) {
      val mid = minOf(low + width, n)
      val high = minOf(low + 2 * width, n)
      if (mid < high) {
        merge(arr, low, mid, high)
      }
      low += 2 * width
    }
    width *= 2
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
