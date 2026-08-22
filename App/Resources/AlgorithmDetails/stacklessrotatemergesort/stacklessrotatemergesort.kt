fun multiSwap(arr: Array<Int>, a: Int, b: Int, len: Int) {
  for (i in 0 until len) {
    val t = arr[a + i]
    arr[a + i] = arr[b + i]
    arr[b + i] = t
  }
}

fun rotate(arr: Array<Int>, a0: Int, m0: Int, b0: Int) {
  var a = a0
  var m = m0
  var b = b0
  var l = m - a
  var r = b - m
  while (l > 0 && r > 0) {
    if (r < l) {
      multiSwap(arr, m - r, m, r)
      b -= r
      m -= r
      l -= r
    } else {
      multiSwap(arr, a, m, l)
      a += l
      m += l
      r -= l
    }
  }
}

// Selects the c smallest combined elements of the two already-sorted runs
// [a, m) and [m, b) into the front half via a single rotation. Uses a
// merge-path (co-rank) binary search over whichever run is shorter: it
// looks for the split count r such that taking r elements from the tail of
// one run and (c - r) from the head of the other yields exactly the c
// smallest values in order, rather than searching for a value directly.
fun partitionMerge(arr: Array<Int>, a: Int, m: Int, b: Int, c: Int) {
  val lenA = m - a
  val lenB = b - m
  if (lenA < 1 || lenB < 1) return

  if (lenB < lenA) {
    val cc = (lenA + lenB) - c
    var r1 = maxOf(0, cc - lenA)
    var r2 = minOf(cc, lenB)
    while (r1 < r2) {
      val ml = r1 + (r2 - r1) / 2
      if (arr[m - (cc - ml)] > arr[b - ml - 1]) {
        r2 = ml
      } else {
        r1 = ml + 1
      }
    }
    rotate(arr, m - (cc - r1), m, b - r1)
  } else {
    var r1 = maxOf(0, c - lenB)
    var r2 = minOf(c, lenA)
    while (r1 < r2) {
      val ml = r1 + (r2 - r1) / 2
      if (arr[a + ml] > arr[m + (c - ml) - 1]) {
        r2 = ml
      } else {
        r1 = ml + 1
      }
    }
    rotate(arr, a + r1, m, m + (c - r1))
  }
}

// Finds the first place inside [a, b) where ascending order breaks, then
// partition-merges the sorted piece before it with the sorted piece after
// it. A no-op if [a, b) is already one ascending run.
fun rotateMerge(arr: Array<Int>, a: Int, b: Int, c: Int) {
  var i = a + 1
  while (i < b && arr[i - 1] <= arr[i]) i++
  if (i < b) partitionMerge(arr, a, i, b, c)
}

fun rotatePartitionMergeSort(arr: Array<Int>, n: Int) {
  if (n < 2) return

  var i = 1
  while (i < n) {
    if (arr[i - 1] > arr[i]) {
      val t = arr[i - 1]
      arr[i - 1] = arr[i]
      arr[i] = t
    }
    i += 2
  }

  var j = 2
  while (j < n) {
    var b1 = 0
    var blockStart = 0
    while (blockStart + j < n) {
      b1 = minOf(blockStart + 2 * j, n)
      partitionMerge(arr, blockStart, blockStart + j, b1, j)
      blockStart += 2 * j
    }

    var k = j / 2
    while (k > 1) {
      var seamStart = 0
      while (seamStart + k < b1) {
        val seamEnd = minOf(seamStart + 2 * k, n)
        rotateMerge(arr, seamStart, seamEnd, k)
        seamStart += 2 * k
      }
      k /= 2
    }

    var m = 1
    while (m < b1) {
      if (arr[m - 1] > arr[m]) {
        val t = arr[m - 1]
        arr[m - 1] = arr[m]
        arr[m] = t
      }
      m += 2
    }

    j *= 2
  }
}

fun sort(arr: Array<Int>) {
  rotatePartitionMergeSort(arr, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
