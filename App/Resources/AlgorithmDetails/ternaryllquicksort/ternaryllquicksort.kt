fun compare3(arr: Array<Int>, a: Int, b: Int): Int {
  if (arr[a] == arr[b]) return 0
  return if (arr[a] > arr[b]) 1 else -1
}

fun selectPivot(arr: Array<Int>, lo: Int, hi: Int): Int {
  val mid = (lo + hi) / 2
  val cLoMid = compare3(arr, lo, mid)
  if (cLoMid == 0) return lo
  val cLoHi = compare3(arr, lo, hi - 1)
  val cMidHi = compare3(arr, mid, hi - 1)
  if (cLoHi == 0 || cMidHi == 0) return hi - 1

  return if (cLoMid < 0) {
    if (cMidHi < 0) mid else (if (cLoHi < 0) hi - 1 else lo)
  } else {
    if (cMidHi > 0) mid else (if (cLoHi < 0) lo else hi - 1)
  }
}

fun partitionTernaryLL(arr: Array<Int>, lo: Int, hi: Int): Pair<Int, Int> {
  val p = selectPivot(arr, lo, hi)
  arr[p] = arr[hi - 1].also { arr[hi - 1] = arr[p] }
  val pivotIndex = hi - 1

  var i = lo
  var k = hi - 1

  var j = lo
  while (j < k) {
    val cmp = compare3(arr, j, pivotIndex)
    if (cmp == 0) {
      k--
      arr[k] = arr[j].also { arr[j] = arr[k] }
      j--
    } else if (cmp < 0) {
      arr[i] = arr[j].also { arr[j] = arr[i] }
      i++
    }
    j++
  }

  for (s in 0 until hi - k) {
    arr[i + s] = arr[hi - 1 - s].also { arr[hi - 1 - s] = arr[i + s] }
  }

  return Pair(i, i + (hi - k))
}

fun quicksortTernaryLL(arr: Array<Int>, lo: Int, hi: Int) {
  if (lo + 1 < hi) {
    val (first, second) = partitionTernaryLL(arr, lo, hi)
    quicksortTernaryLL(arr, lo, first)
    quicksortTernaryLL(arr, second, hi)
  }
}

fun sort(arr: Array<Int>) {
  quicksortTernaryLL(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
