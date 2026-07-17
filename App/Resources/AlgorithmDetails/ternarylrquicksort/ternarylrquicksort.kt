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

fun quicksortTernaryLR(arr: Array<Int>, lo: Int, hi: Int) {
  if (hi <= lo) return

  val piv = selectPivot(arr, lo, hi + 1)
  arr[piv] = arr[hi].also { arr[hi] = arr[piv] }
  val pivotIndex = hi

  var i = lo
  var j = hi - 1
  var p = lo
  var q = hi - 1

  while (true) {
    var cmp: Int
    while (i <= j) {
      cmp = compare3(arr, i, pivotIndex)
      if (cmp > 0) break
      if (cmp == 0) {
        arr[i] = arr[p].also { arr[p] = arr[i] }
        p++
      }
      i++
    }
    while (i <= j) {
      cmp = compare3(arr, j, pivotIndex)
      if (cmp < 0) break
      if (cmp == 0) {
        arr[j] = arr[q].also { arr[q] = arr[j] }
        q--
      }
      j--
    }
    if (i > j) break
    arr[i] = arr[j].also { arr[j] = arr[i] }
    i++
    j--
  }

  arr[i] = arr[hi].also { arr[hi] = arr[i] }

  val numLess = i - p
  val numGreater = q - j

  j = i - 1
  i = i + 1

  val pe = lo + minOf(p - lo, numLess)
  var k = lo
  while (k < pe) {
    arr[k] = arr[j].also { arr[j] = arr[k] }
    k++
    j--
  }

  val qe = hi - 1 - minOf(hi - 1 - q, numGreater - 1)
  k = hi - 1
  while (k > qe) {
    arr[i] = arr[k].also { arr[k] = arr[i] }
    k--
    i++
  }

  quicksortTernaryLR(arr, lo, lo + numLess - 1)
  quicksortTernaryLR(arr, hi - numGreater + 1, hi)
}

fun sort(arr: Array<Int>) {
  quicksortTernaryLR(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
