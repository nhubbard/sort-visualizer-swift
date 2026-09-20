fun blockSwap(arr: Array<Int>, a: Int, b: Int, size: Int) {
  for (offset in 0 until size) {
    val x = a - size + 1 + offset
    val y = b - size + 1 + offset
    val tmp = arr[x]; arr[x] = arr[y]; arr[y] = tmp
  }
}
fun blockInsert(arr: Array<Int>, end: Int, target: Int, size: Int) {
  var end = end
  while (end - size >= target) { blockSwap(arr, end - size, end, size); end -= size }
}
fun blockReversal(arr: Array<Int>, start: Int, finish: Int, size: Int) {
  var a = start
  var b = finish - size
  while (b > a) { blockSwap(arr, a, b, size); a += size; b -= size }
}
fun blockSearch(arr: Array<Int>, start: Int, finish: Int, size: Int, value: Int): Int {
  var a = start
  var b = finish
  while (a < b) {
    val mid = a + (((b - a) / size) / 2) * size
    if (value < arr[mid]) b = mid else a = mid + size
  }
  return a
}
fun order(arr: Array<Int>, a: Int, b: Int, size: Int) {
  var i = a
  var j = i + size
  while (j < b) { blockInsert(arr, j, i, size); i += size; j += 2 * size }
  val mid = a + (((b - a) / size) / 2) * size
  blockReversal(arr, mid, b, size)
}
fun sort(arr: Array<Int>) {
  val length = arr.size
  if (length < 2) return
  var k = 1
  while (2 * k <= length) {
    var i = 2 * k - 1
    while (i < length) {
      if (arr[i - k] > arr[i]) blockSwap(arr, i - k, i, k)
      i += 2 * k
    }
    k *= 2
  }
  while (k > 0) {
    val a = k - 1
    var i = a + 2 * k
    var g = 2
    var p = 4
    while (i + 2 * k * g - k <= length) {
      order(arr, i, i + 2 * k * g - k, k)
      val b = a + k * (p - 1)
      i += k * g - k
      var j = i
      while (j < i + k * g) {
        blockInsert(arr, j, blockSearch(arr, a, b, k, arr[j]), k)
        j += k
      }
      i += k * g + k
      g = p - g; p *= 2
    }
    while (i < length) {
      blockInsert(arr, i, blockSearch(arr, a, i, k, arr[i]), k)
      i += 2 * k
    }
    k /= 2
  }
}

fun main() {
  var array = arrayOf<Int>(
    34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9,
    50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
