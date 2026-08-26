const val INSERTION_THRESHOLD = 24

// Sorts arr[start..end) in place using a plain binary-search insertion sort -- the base case
// once a segment shrinks small enough that further partitioning isn't worth it.
fun binaryInsertionSort(arr: Array<Int>, start: Int, end: Int) {
  for (i in start until end) {
    val value = arr[i]
    var lo = start
    var hi = i
    while (lo < hi) {
      val mid = lo + (hi - lo) / 2
      if (value < arr[mid]) {
        hi = mid
      } else {
        lo = mid + 1
      }
    }
    var j = i - 1
    while (j >= lo) {
      arr[j + 1] = arr[j]
      j--
    }
    arr[lo] = value
  }
}

// Finds where the value at targetIndex belongs among arr[start..end), ties resolving toward the
// front (a plain lower-bound binary search).
fun lowerBoundIndex(arr: Array<Int>, start: Int, end: Int, targetIndex: Int): Int {
  var lo = start
  var hi = end
  while (lo < hi) {
    val mid = lo + (hi - lo) / 2
    if (arr[targetIndex] <= arr[mid]) {
      hi = mid
    } else {
      lo = mid + 1
    }
  }
  return lo
}

// Dual-pivot partition of arr[start..end). `scratch` is a fixed index outside this range,
// borrowed briefly as scratch space by the closing rotation and immediately restored. Returns
// the boundary between the low region and everything at or above the smaller of the two pivots.
fun partition(arr: Array<Int>, start: Int, endIn: Int, scratch: Int): Int {
  var end = endIn
  val m1 = (start + start + end) / 3
  val m2 = (start + end + end) / 3

  if (arr[m1] > arr[m2]) {
    val t = arr[m1]
    arr[m1] = arr[start]
    arr[start] = t
    end--
    val t2 = arr[m2]
    arr[m2] = arr[end]
    arr[end] = t2
  } else {
    val t = arr[m2]
    arr[m2] = arr[start]
    arr[start] = t
    end--
    val t2 = arr[m1]
    arr[m1] = arr[end]
    arr[end] = t2
  }

  var low = start
  var high = end
  // Reversed from the usual low/high naming: after the swaps above, `start` holds the larger of
  // the two chosen medians and `end` the smaller. Neither position moves again until the
  // closing rotation below, so their values are safe to hold onto directly.
  val pivotMax = arr[start]
  val pivotMin = arr[end]

  var k = low + 1
  while (k < high) {
    if (arr[k] < pivotMin) {
      low++
      val t = arr[k]
      arr[k] = arr[low]
      arr[low] = t
    } else if (arr[k] >= pivotMax) {
      do {
        high--
      } while (high > k && arr[high] >= pivotMax)
      val t = arr[k]
      arr[k] = arr[high]
      arr[high] = t
      if (arr[k] < pivotMin) {
        low++
        val t2 = arr[k]
        arr[k] = arr[low]
        arr[low] = t2
      }
    }
    k++
  }

  val t = arr[start]
  arr[start] = arr[low]
  arr[low] = t
  // Three-way rotation: the value at `end` moves to `scratch`, whatever was borrowed from
  // `scratch` moves to `high`, and whatever was at `high` moves to `end`.
  val displaced = arr[end]
  arr[end] = arr[high]
  arr[high] = arr[scratch]
  arr[scratch] = displaced

  return low
}

// Sorts arr[start..end) in place with no recursion: a single loop processes one segment at a
// time, shrinking and partitioning it down to INSERTION_THRESHOLD elements, finishing with
// binaryInsertionSort, then advancing past it to the next segment.
fun quickSort(arr: Array<Int>, start: Int, endIn: Int) {
  var end = endIn

  // Move every copy of this range's maximum value to the very end first. Those elements are
  // already correctly placed relative to everything else, so the rest of the algorithm never
  // has to look at them again -- and the boundary in front of them becomes fixed scratch space
  // partition can borrow from.
  var maxValue = arr[start]
  for (i in (start + 1) until end) {
    if (arr[i] > maxValue) maxValue = arr[i]
  }

  var tail = end
  for (i in (end - 1) downTo start) {
    if (arr[i] == maxValue) {
      tail--
      val t = arr[i]
      arr[i] = arr[tail]
      arr[tail] = t
    }
  }

  var a = start
  var segmentEnd = tail
  // False right after skipping a run of duplicates below means the next median-of-three should
  // refresh one of its two candidates, since reusing them would just compare equal again.
  var reuseMedianCandidates = true

  while (true) {
    while (segmentEnd - a > INSERTION_THRESHOLD) {
      if (!reuseMedianCandidates) {
        val m = (a + a + segmentEnd) / 3
        val t = arr[a]
        arr[a] = arr[m]
        arr[m] = t
      }
      segmentEnd = partition(arr, a, segmentEnd, tail)
    }

    binaryInsertionSort(arr, a, segmentEnd)

    a = segmentEnd + 1
    if (a >= tail) {
      if (a - 1 < tail) {
        val t = arr[a - 1]
        arr[a - 1] = arr[tail]
        arr[tail] = t
      }
      return
    }

    segmentEnd = lowerBoundIndex(arr, a, tail, a - 1)
    val t = arr[a - 1]
    arr[a - 1] = arr[tail]
    arr[tail] = t

    reuseMedianCandidates = true
    while (a < segmentEnd && arr[a - 1] == arr[a]) {
      reuseMedianCandidates = false
      a++
    }
    if (a == segmentEnd) reuseMedianCandidates = true
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  quickSort(arr, 0, n)
}

fun main() {
  var array =
    arrayOf<Int>(
      55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
      21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
    )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
