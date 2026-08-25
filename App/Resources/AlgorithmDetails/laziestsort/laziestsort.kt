fun binaryInsertionSort(arr: Array<Int>, lo: Int, hi: Int) {
  for (i in lo + 1 until hi) {
    val key = arr[i]
    var left = lo
    var right = i
    while (left < right) {
      val mid = (left + right) / 2
      if (arr[mid] <= key) {
        left = mid + 1
      } else {
        right = mid
      }
    }
    for (j in i downTo left + 1) {
      arr[j] = arr[j - 1]
    }
    arr[left] = key
  }
}

fun swapRange(arr: Array<Int>, a: Int, b: Int, length: Int) {
  for (i in 0 until length) {
    val t = arr[a + i]
    arr[a + i] = arr[b + i]
    arr[b + i] = t
  }
}

// Swaps the two adjacent blocks arr[lo, mid) and arr[mid, hi) so their order is
// reversed, using no auxiliary storage: the smaller of the two remaining pieces is
// always swapped whole against an equal-sized piece of the other, which shrinks one
// piece to nothing a little at a time until both are exhausted.
fun rotate(arr: Array<Int>, lo: Int, mid: Int, hi: Int) {
  var i = mid - lo
  var j = hi - mid
  if (i == 0 || j == 0) {
    return
  }
  while (i != j) {
    if (i < j) {
      swapRange(arr, mid - i, mid + j - i, i)
      j -= i
    } else {
      swapRange(arr, mid - i, mid, j)
      i -= j
    }
  }
  swapRange(arr, mid - i, mid, i)
}

// Finds the first index in [lo, hi) whose element is not less than value, by doubling
// the step size until it overshoots and then binary-searching the resulting bracket,
// rather than scanning one element at a time. Assumes arr[lo] < value.
fun gallop(arr: Array<Int>, lo: Int, hi: Int, value: Int): Int {
  var left = lo
  var step = 1
  var right = lo + step
  while (right < hi && arr[right] < value) {
    left = right
    step *= 2
    right = lo + step
  }
  right = minOf(right, hi)
  while (right - left > 1) {
    val mid = (left + right) / 2
    if (arr[mid] < value) {
      left = mid
    } else {
      right = mid
    }
  }
  return right
}

// Merges the sorted run arr[lo, mid) into the sorted run arr[mid, hi) in place. `left`
// tracks the first not-yet-placed element of the left run, and `right` tracks the start
// of the not-yet-consumed remainder of the right run.
fun merge(arr: Array<Int>, lo: Int, mid: Int, hi: Int) {
  var left = lo
  var right = mid
  while (left < right && right < hi) {
    if (arr[left] <= arr[right]) {
      left++
    } else {
      val boundary = gallop(arr, right, hi, arr[left])
      rotate(arr, left, right, boundary)
      left += boundary - right
      right = boundary
    }
  }
}

fun integerSqrt(n: Int): Int {
  var r = Math.sqrt(n.toDouble()).toInt()
  while ((r + 1).toLong() * (r + 1) <= n) {
    r++
  }
  while (r.toLong() * r > n) {
    r--
  }
  return r
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 16) {
    binaryInsertionSort(arr, 0, n)
    return
  }

  val blockSize = maxOf(16, integerSqrt(n))
  var low = 0
  while (low < n) {
    binaryInsertionSort(arr, low, minOf(low + blockSize, n))
    low += blockSize
  }

  // Merge blocks back to front: the already-sorted run always starts at mergedStart,
  // and each step folds the block immediately before it into that run.
  val numBlocks = (n + blockSize - 1) / blockSize
  var mergedStart = (numBlocks - 1) * blockSize
  for (i in numBlocks - 2 downTo 0) {
    val leftStart = i * blockSize
    merge(arr, leftStart, mergedStart, n)
    mergedStart = leftStart
  }
}

fun main() {
  var array = arrayOf<Int>(
    55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44, 12,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
