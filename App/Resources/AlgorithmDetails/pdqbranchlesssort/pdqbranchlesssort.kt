const val INSERT_SORT_THRESHOLD = 24
const val NINTHER_THRESHOLD = 128
const val PARTIAL_INSERT_SORT_LIMIT = 8
const val BLOCK_SIZE = 64
const val CACHELINE_SIZE = 64

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

// Integer division truncated toward zero. Kotlin's `/` already truncates toward zero for
// negative operands, which is what the pivot-position arithmetic below needs at the one
// call site where the dividend can go negative -- this helper just names that intent.
fun truncDiv(a: Int, b: Int): Int = a / b

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

fun swapOffsets(
  arr: Array<Int>, first: Int, last: Int, leftOffsets: IntArray, leftPos: Int,
  rightOffsets: IntArray, rightPos: Int, num: Int, useSwaps: Boolean
) {
  if (useSwaps) {
    for (i in 0 until num) {
      swap(arr, first + leftOffsets[leftPos + i], last - rightOffsets[rightPos + i])
    }
  } else if (num > 0) {
    var left = first + leftOffsets[leftPos]
    var right = last - rightOffsets[rightPos]
    val tmp = arr[left]
    arr[left] = arr[right]
    for (i in 1 until num) {
      left = first + leftOffsets[leftPos + i]
      arr[right] = arr[left]
      right = last - rightOffsets[rightPos + i]
      arr[left] = arr[right]
    }
    arr[right] = tmp
  }
}

fun partRightBranchless(
  arr: Array<Int>, begin: Int, end: Int, leftOffsets: IntArray, rightOffsets: IntArray
): Pair<Int, Boolean> {
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
  if (!alreadyParted) {
    swap(arr, first, last)
    first++
  }

  var leftNum = 0
  var rightNum = 0
  var leftStart = 0
  var rightStart = 0

  while (last - first > 2 * BLOCK_SIZE) {
    if (leftNum == 0) {
      leftStart = 0
      var it = first
      for (i in 0 until BLOCK_SIZE) {
        leftOffsets[leftNum] = i
        if (!(arr[it] < pivot)) leftNum++
        it++
      }
    }
    if (rightNum == 0) {
      rightStart = 0
      var it = last
      for (i in 0 until BLOCK_SIZE) {
        it--
        rightOffsets[rightNum] = i + 1
        if (arr[it] < pivot) rightNum++
      }
    }

    val num = minOf(leftNum, rightNum)
    swapOffsets(arr, first, last, leftOffsets, leftStart, rightOffsets, rightStart, num, leftNum == rightNum)
    leftNum -= num; rightNum -= num
    leftStart += num; rightStart += num
    if (leftNum == 0) first += BLOCK_SIZE
    if (rightNum == 0) last -= BLOCK_SIZE
  }

  var leftSize: Int
  var rightSize: Int
  val unknownLeft = (last - first) - (if (rightNum != 0 || leftNum != 0) BLOCK_SIZE else 0)
  if (rightNum != 0) {
    leftSize = unknownLeft
    rightSize = BLOCK_SIZE
  } else if (leftNum != 0) {
    leftSize = BLOCK_SIZE
    rightSize = unknownLeft
  } else {
    leftSize = truncDiv(unknownLeft, 2)
    rightSize = unknownLeft - leftSize
  }

  if (unknownLeft != 0 && leftNum == 0) {
    leftStart = 0
    var it = first
    for (i in 0 until leftSize) {
      leftOffsets[leftNum] = i
      if (!(arr[it] < pivot)) leftNum++
      it++
    }
  }

  if (unknownLeft != 0 && rightNum == 0) {
    rightStart = 0
    var it = last
    for (i in 0 until rightSize) {
      it--
      rightOffsets[rightNum] = i + 1
      if (arr[it] < pivot) rightNum++
    }
  }

  val num = minOf(leftNum, rightNum)
  swapOffsets(arr, first, last, leftOffsets, leftStart, rightOffsets, rightStart, num, leftNum == rightNum)
  leftNum -= num; rightNum -= num
  leftStart += num; rightStart += num
  if (leftNum == 0) first += leftSize
  if (rightNum == 0) last -= rightSize

  var leftOffsetsPos = 0
  var rightOffsetsPos = 0

  if (leftNum != 0) {
    leftOffsetsPos += leftStart
    while (leftNum != 0) {
      leftNum--
      last--
      swap(arr, first + leftOffsets[leftOffsetsPos + leftNum], last)
    }
    first = last
  }

  if (rightNum != 0) {
    rightOffsetsPos += rightStart
    while (rightNum != 0) {
      rightNum--
      swap(arr, last - rightOffsets[rightOffsetsPos + rightNum], first)
      first++
    }
    last = first
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

fun pdqLoop(arr: Array<Int>, begin0: Int, end: Int, badAllowed0: Int, leftOffsets: IntArray, rightOffsets: IntArray) {
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

    val (pivotPos, alreadyParted) = partRightBranchless(arr, begin, end, leftOffsets, rightOffsets)

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

    pdqLoop(arr, begin, pivotPos, badAllowed, leftOffsets, rightOffsets)
    begin = pivotPos + 1
    leftmost = false
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  val leftOffsets = IntArray(BLOCK_SIZE + CACHELINE_SIZE)
  val rightOffsets = IntArray(BLOCK_SIZE + CACHELINE_SIZE)
  pdqLoop(arr, 0, n, pdqLog(n), leftOffsets, rightOffsets)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
