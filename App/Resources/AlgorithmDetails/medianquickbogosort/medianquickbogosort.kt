fun sort(arr: Array<Int>, start: Int = 0, end: Int = arr.size) {
  if (start >= end - 1) {
    return
  }
  val mid = (start + end) / 2

  fun isSplit(): Boolean {
    var lowMax = arr[start]
    for (i in start + 1 until mid) {
      if (arr[i] > lowMax) {
        lowMax = arr[i]
      }
    }
    for (i in mid until end) {
      if (lowMax > arr[i]) {
        return false
      }
    }
    return true
  }

  while (!isSplit()) {
    val sub = arr.copyOfRange(start, end).toMutableList()
    sub.shuffle()
    for (i in start until end) {
      arr[i] = sub[i - start]
    }
  }

  sort(arr, start, mid)
  sort(arr, mid, end)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
