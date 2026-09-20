const val RECENCY = 8
const val EARLY_OUT_TEST_AT = 4
const val EARLY_OUT_DISORDER_FRACTION = 0.6

// Branched PDQ fallback, matching the app PDQSortingTemplate.
const val INSERT_SORT_THRESHOLD = 24
const val NINTHER_THRESHOLD = 128
const val PARTIAL_INSERT_SORT_LIMIT = 8

fun sort(arr: MutableList<Int>) {
  val length = arr.size
  if (length < 2) return

  val dropped = mutableListOf<Int>()
  var numDroppedInARow = 0
  var read = 0
  var write = 0
  var iteration = 0
  val earlyOutStop = length / EARLY_OUT_TEST_AT

  while (read < length) {
    iteration++
    if (iteration == earlyOutStop && dropped.size > read * EARLY_OUT_DISORDER_FRACTION) {
      // Too disordered for the adaptive approach to be worth it: flush what's been dropped so
      // far back into the array and fall back to a plain full sort.
      for (value in dropped) {
        arr[write] = value
        write++
      }
      dropped.clear()
      pdqSort(arr, 0, length)
      return
    }

    if (write == 0 || arr[read] >= arr[write - 1]) {
      // In order -- keep it.
      arr[write] = arr[read]
      write++
      read++
      numDroppedInARow = 0
    } else if (numDroppedInARow == 0 && write >= 2 && arr[read] >= arr[write - 2]) {
      // Quick undo: the element two back would have accepted this one just fine, so drop the
      // one right before it instead of the new element.
      dropped.add(arr[write - 1])
      arr[write - 1] = arr[read]
      read++
    } else if (numDroppedInARow < RECENCY) {
      dropped.add(arr[read])
      read++
      numDroppedInARow++
    } else {
      // Accepting something `numDroppedInARow` elements back made every subsequent element
      // drop -- that accept was a mistake. Undo it, and any other recently accepted elements
      // bigger than the dropped run's maximum.
      repeat(numDroppedInARow) { dropped.removeAt(dropped.size - 1) }
      read -= numDroppedInARow

      var numBacktracked = 1
      write--

      var maxOfDropped = read
      for (i in (read + 1)..(read + numDroppedInARow)) {
        if (arr[i] > maxOfDropped) maxOfDropped = arr[i]
      }

      while (write >= 1 && maxOfDropped < arr[write - 1]) {
        write--
        numBacktracked++
      }

      for (i in write until (write + numBacktracked)) {
        dropped.add(arr[i])
      }

      numDroppedInARow = 0
    }
  }

  for (offset in dropped.indices) {
    arr[write + offset] = dropped[offset]
  }

  pdqSort(arr, write, length)

  // Copy the now-sorted dropped tail before the final backward merge starts overwriting
  // arr[write..] in place.
  val buffer = arr.subList(write, write + dropped.size).toList()

  var i = buffer.size - 1
  var j = write - 1
  var k = length - 1

  while (i >= 0) {
    if (j < 0 || buffer[i] > arr[j]) {
      arr[k] = buffer[i]
      k--
      i--
    } else {
      arr[k] = arr[j]
      k--
      j--
    }
  }
}

fun pdqLog(n0: Int): Int {
  var n = n0
  var log = 0
  while (true) {
    n = n shr 1
    if (n == 0) break
    log++
  }
  return log
}

fun swap(arr: MutableList<Int>, a: Int, b: Int) {
  val t = arr[a]
  arr[a] = arr[b]
  arr[b] = t
}

fun insertSort(arr: MutableList<Int>, begin: Int, end: Int) {
  for (cur in begin + 1 until end) {
    if (arr[cur] < arr[cur - 1]) {
      val tmp = arr[cur]
      var sift = cur
      var siftMinusOne = cur - 1
      do {
        arr[sift--] = arr[siftMinusOne--]
      } while (sift != begin && tmp < arr[siftMinusOne])
      arr[sift] = tmp
    }
  }
}

fun unguardInsertSort(arr: MutableList<Int>, begin: Int, end: Int) {
  for (cur in begin + 1 until end) {
    if (arr[cur] < arr[cur - 1]) {
      val tmp = arr[cur]
      var sift = cur
      var siftMinusOne = cur - 1
      do {
        arr[sift--] = arr[siftMinusOne--]
      } while (tmp < arr[siftMinusOne])
      arr[sift] = tmp
    }
  }
}

fun partialInsertSort(arr: MutableList<Int>, begin: Int, end: Int): Boolean {
  var limit = 0
  for (cur in begin + 1 until end) {
    if (limit > PARTIAL_INSERT_SORT_LIMIT) return false
    if (arr[cur] < arr[cur - 1]) {
      val tmp = arr[cur]
      var sift = cur
      var siftMinusOne = cur - 1
      do {
        arr[sift--] = arr[siftMinusOne--]
      } while (sift != begin && tmp < arr[siftMinusOne])
      arr[sift] = tmp
      limit += cur - sift
    }
  }
  return true
}

fun sortTwo(arr: MutableList<Int>, a: Int, b: Int) {
  if (arr[b] < arr[a]) swap(arr, a, b)
}

fun sortThree(arr: MutableList<Int>, a: Int, b: Int, c: Int) {
  sortTwo(arr, a, b)
  sortTwo(arr, b, c)
  sortTwo(arr, a, b)
}

fun partRight(arr: MutableList<Int>, begin: Int, end: Int): Pair<Int, Boolean> {
  val pivot = arr[begin]
  var first = begin
  var last = end

  first++
  while (arr[first] < pivot) first++

  if (first - 1 == begin) {
    last--
    while (first < last && !(arr[last] < pivot)) last--
  } else {
    last--
    while (!(arr[last] < pivot)) last--
  }

  val alreadyParted = first >= last
  while (first < last) {
    swap(arr, first, last)
    first++
    while (arr[first] < pivot) first++
    last--
    while (!(arr[last] < pivot)) last--
  }

  val pivotPos = first - 1
  arr[begin] = arr[pivotPos]
  arr[pivotPos] = pivot

  return Pair(pivotPos, alreadyParted)
}

fun partLeft(arr: MutableList<Int>, begin: Int, end: Int): Int {
  val pivot = arr[begin]
  var first = begin
  var last = end

  last--
  while (pivot < arr[last]) last--

  if (last + 1 == end) {
    first++
    while (first < last && !(pivot < arr[first])) first++
  } else {
    first++
    while (!(pivot < arr[first])) first++
  }

  while (first < last) {
    swap(arr, first, last)
    last--
    while (pivot < arr[last]) last--
    first++
    while (!(pivot < arr[first])) first++
  }

  val pivotPos = last
  arr[begin] = arr[pivotPos]
  arr[pivotPos] = pivot
  return pivotPos
}

fun siftDown(arr: MutableList<Int>, begin: Int, root0: Int, size: Int) {
  var root = root0
  while (true) {
    var child = 2 * root + 1
    if (child >= size) break
    if (child + 1 < size && arr[begin + child] < arr[begin + child + 1]) child++
    if (arr[begin + root] < arr[begin + child]) {
      swap(arr, begin + root, begin + child)
      root = child
    } else {
      break
    }
  }
}

fun heapSort(arr: MutableList<Int>, begin: Int, end: Int) {
  val n = end - begin
  for (i in n / 2 - 1 downTo 0) siftDown(arr, begin, i, n)
  for (i in n - 1 downTo 1) {
    swap(arr, begin, begin + i)
    siftDown(arr, begin, 0, i)
  }
}

fun pdqLoop(arr: MutableList<Int>, begin0: Int, end: Int, badAllowed0: Int) {
  var begin = begin0
  var badAllowed = badAllowed0
  var leftmost = true
  while (true) {
    val size = end - begin

    if (size < INSERT_SORT_THRESHOLD) {
      if (leftmost) insertSort(arr, begin, end)
      else unguardInsertSort(arr, begin, end)
      return
    }

    val halfSize = size / 2
    if (size > NINTHER_THRESHOLD) {
      sortThree(arr, begin, begin + halfSize, end - 1)
      sortThree(arr, begin + 1, begin + halfSize - 1, end - 2)
      sortThree(arr, begin + 2, begin + halfSize + 1, end - 3)
      sortThree(arr, begin + halfSize - 1, begin + halfSize, begin + halfSize + 1)
      swap(arr, begin, begin + halfSize)
    } else {
      sortThree(arr, begin + halfSize, begin, end - 1)
    }

    if (!leftmost && !(arr[begin - 1] < arr[begin])) {
      begin = partLeft(arr, begin, end) + 1
      continue
    }

    val (pivotPos, alreadyParted) = partRight(arr, begin, end)

    val leftSize = pivotPos - begin
    val rightSize = end - (pivotPos + 1)
    val highUnbalance = leftSize < size / 8 || rightSize < size / 8

    if (highUnbalance) {
      badAllowed--
      if (badAllowed == 0) {
        heapSort(arr, begin, end)
        return
      }

      if (leftSize >= INSERT_SORT_THRESHOLD) {
        swap(arr, begin, begin + leftSize / 4)
        swap(arr, pivotPos - 1, pivotPos - leftSize / 4)
        if (leftSize > NINTHER_THRESHOLD) {
          swap(arr, begin + 1, begin + (leftSize / 4 + 1))
          swap(arr, begin + 2, begin + (leftSize / 4 + 2))
          swap(arr, pivotPos - 2, pivotPos - (leftSize / 4 + 1))
          swap(arr, pivotPos - 3, pivotPos - (leftSize / 4 + 2))
        }
      }

      if (rightSize >= INSERT_SORT_THRESHOLD) {
        swap(arr, pivotPos + 1, pivotPos + (1 + rightSize / 4))
        swap(arr, end - 1, end - rightSize / 4)
        if (rightSize > NINTHER_THRESHOLD) {
          swap(arr, pivotPos + 2, pivotPos + (2 + rightSize / 4))
          swap(arr, pivotPos + 3, pivotPos + (3 + rightSize / 4))
          swap(arr, end - 2, end - (1 + rightSize / 4))
          swap(arr, end - 3, end - (2 + rightSize / 4))
        }
      }
    } else {
      if (alreadyParted && partialInsertSort(arr, begin, pivotPos) && partialInsertSort(arr, pivotPos + 1, end)) {
        return
      }
    }

    pdqLoop(arr, begin, pivotPos, badAllowed)
    begin = pivotPos + 1
    leftmost = false
  }
}

fun pdqSort(arr: MutableList<Int>, begin: Int, end: Int) {
  if (end - begin > 1) {
    pdqLoop(arr, begin, end, pdqLog(end - begin))
  }
}



fun main() {
  val array =
    mutableListOf(
      0, 1, 2, 3, 4, 9, 6, 7, 8, 5, 10, 11, 12, 13, 14, 15,
      21, 17, 18, 19, 20, 16, 22, 23, 24, 28, 26, 27, 25, 29,
    )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
