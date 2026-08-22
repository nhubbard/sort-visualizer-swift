fun sort(arr: Array<Int>, start: Int = 0, end: Int = arr.size) {
  if (start >= end - 1) {
    return
  }
  val mid = (start + end) / 2
  sort(arr, start, mid)
  sort(arr, mid, end)

  val saved = arr.copyOfRange(start, end)

  fun isSorted(): Boolean {
    for (i in start until end - 1) {
      if (arr[i] > arr[i + 1]) {
        return false
      }
    }
    return true
  }

  while (!isSorted()) {
    val highPositions = (0 until end - start).shuffled().take(end - mid).toSet()

    var low = 0
    var high = mid - start
    for (offset in 0 until end - start) {
      if (offset in highPositions) {
        arr[start + offset] = saved[high]
        high++
      } else {
        arr[start + offset] = saved[low]
        low++
      }
    }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
