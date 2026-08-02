const val INSERT_SORT_THRESHOLD = 24
const val NINTHER_THRESHOLD = 128
const val PARTIAL_INSERT_SORT_LIMIT = 8

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

fun swap(arr: Array<Int>, a: Int, b: Int) {
  val t = arr[a]
  arr[a] = arr[b]
  arr[b] = t
}

fun insertSort(arr: Array<Int>, begin: Int, end: Int) {
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

fun unguardInsertSort(arr: Array<Int>, begin: Int, end: Int) {
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

fun partialInsertSort(arr: Array<Int>, begin: Int, end: Int): Boolean {
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

fun sortTwo(arr: Array<Int>, a: Int, b: Int) {
  if (arr[b] < arr[a]) swap(arr, a, b)
}

fun sortThree(arr: Array<Int>, a: Int, b: Int, c: Int) {
  sortTwo(arr, a, b)
  sortTwo(arr, b, c)
  sortTwo(arr, a, b)
}

fun partRight(arr: Array<Int>, begin: Int, end: Int): Pair<Int, Boolean> {
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

fun partLeft(arr: Array<Int>, begin: Int, end: Int): Int {
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

fun siftDown(arr: Array<Int>, begin: Int, root0: Int, size: Int) {
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

fun heapSort(arr: Array<Int>, begin: Int, end: Int) {
  val n = end - begin
  for (i in n / 2 - 1 downTo 0) siftDown(arr, begin, i, n)
  for (i in n - 1 downTo 1) {
    swap(arr, begin, begin + i)
    siftDown(arr, begin, 0, i)
  }
}

fun pdqLoop(arr: Array<Int>, begin0: Int, end: Int, badAllowed0: Int) {
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

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  pdqLoop(arr, 0, n, pdqLog(n))
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
