fun classify(value: Int, minValue: Int, c: Double): Int {
  return ((value - minValue) * c).toInt() + 1
}

fun flashSort(array: IntArray) {
  val n = array.size
  if (n == 0) return

  val m = (0.2 * n).toInt() + 2

  var minValue = array[0]
  var maxValue = array[0]
  var maxIndex = 0

  var i = 1
  while (i < n - 1) {
    val small: Int
    val big: Int
    val bigIndex: Int
    if (array[i] < array[i + 1]) {
      small = array[i]; big = array[i + 1]; bigIndex = i + 1
    } else {
      big = array[i]; bigIndex = i; small = array[i + 1]
    }
    if (big > maxValue) { maxValue = big; maxIndex = bigIndex }
    if (small < minValue) { minValue = small }
    i += 2
  }

  val last = array[n - 1]
  if (last < minValue) {
    minValue = last
  } else if (last > maxValue) {
    maxValue = last
    maxIndex = n - 1
  }

  if (maxValue == minValue) return

  val L = IntArray(m + 1)
  val c = (m - 1.0) / (maxValue - minValue)

  for (h in 0 until n) {
    val k = classify(array[h], minValue, c)
    L[k] += 1
  }

  for (k in 2..m) {
    L[k] += L[k - 1]
  }

  val tmpSwap = array[maxIndex]
  array[maxIndex] = array[0]
  array[0] = tmpSwap

  var j = 0
  var k = m
  var numMoves = 0
  while (numMoves < n) {
    while (j >= L[k]) {
      j++
      k = classify(array[j], minValue, c)
    }

    var evicted = array[j]
    while (j < L[k]) {
      k = classify(evicted, minValue, c)
      val location = L[k] - 1
      val temp = array[location]
      array[location] = evicted
      evicted = temp
      L[k] -= 1
      numMoves++
    }
  }

  for (idx in 1 until n) {
    val current = array[idx]
    var pos = idx - 1
    while (pos >= 0 && array[pos] > current) {
      array[pos + 1] = array[pos]
      pos--
    }
    array[pos + 1] = current
  }
}

fun sort(arr: IntArray) {
  flashSort(arr)
}

fun main() {
  val array = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
