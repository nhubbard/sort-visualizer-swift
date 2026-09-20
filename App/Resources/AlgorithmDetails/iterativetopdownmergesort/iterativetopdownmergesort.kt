fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  val scratch = Array(n) { 0 }
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
      merge(arr, scratch, low, mid, high)
      i += 2
    }
    subarrayCount /= 2
  }
}

fun merge(arr: Array<Int>, scratch: Array<Int>, low: Int, mid: Int, high: Int) {
  var left = low
  var right = mid
  var out = low
  while (left < mid && right < high) {
    if (arr[left] <= arr[right]) {
      scratch[out] = arr[left]
      left++
    } else {
      scratch[out] = arr[right]
      right++
    }
    out++
  }
  while (left < mid) {
    scratch[out++] = arr[left++]
  }
  while (right < high) {
    scratch[out++] = arr[right++]
  }
  for (i in low until high) arr[i] = scratch[i]
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
