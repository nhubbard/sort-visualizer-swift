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
  var subarrayCount = 1
  while (subarrayCount < n) {
    subarrayCount *= 2
  }

  while (subarrayCount > 1) {
    var i = 0
    while (i < subarrayCount) {
      val low = n * i / subarrayCount
      val mid = n * (i + 1) / subarrayCount
      val high = n * (i + 2) / subarrayCount
      merge(arr, low, mid, high)
      i += 2
    }
    subarrayCount /= 2
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