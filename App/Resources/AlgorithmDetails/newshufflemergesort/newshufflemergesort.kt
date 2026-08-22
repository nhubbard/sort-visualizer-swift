fun multiSwap(arr: Array<Int>, i: Int, j: Int, length: Int) {
  for (k in 0 until length) {
    val t = arr[i + k]
    arr[i + k] = arr[j + k]
    arr[j + k] = t
  }
}

fun rotate(arr: Array<Int>, mid0: Int, leftLen0: Int, rightLen0: Int) {
  var mid = mid0
  var leftLen = leftLen0
  var rightLen = rightLen0
  while (leftLen > 0 && rightLen > 0) {
    if (leftLen > rightLen) {
      multiSwap(arr, mid - rightLen, mid, rightLen)
      mid -= rightLen
      leftLen -= rightLen
    } else {
      multiSwap(arr, mid - leftLen, mid, leftLen)
      mid += leftLen
      rightLen -= leftLen
    }
  }
}

// Perfect-shuffles a chunk of `size - 1` elements by following the cycles of i -> i*2 mod size.
fun shuffleBlock(arr: Array<Int>, start: Int, size: Int) {
  var i = 1
  while (i < size) {
    var current = arr[start + i - 1]
    var j = (i * 2) % size
    while (j != i) {
      val nextVal = arr[start + j - 1]
      arr[start + j - 1] = current
      current = nextVal
      j = (j * 2) % size
    }
    arr[start + i - 1] = current
    i *= 3
  }
}

// A single riffle shuffle only closes into clean cycles at power-of-three sizes, so shuffling
// happens in power-of-three chunks, rotating the next chunk's tail into place before each one.
fun shuffle(arr: Array<Int>, start0: Int, end: Int) {
  var start = start0
  while (end - start > 1) {
    val half = (end - start) / 2
    var chunk = 1
    while (chunk * 3 - 1 <= 2 * half) {
      chunk *= 3
    }
    val tail = (chunk - 1) / 2
    rotate(arr, start + half, half - tail, tail)
    shuffleBlock(arr, start, chunk)
    start += chunk - 1
  }
}

fun rotateShuffledEqual(arr: Array<Int>, i: Int, j: Int, size: Int) {
  var k = 0
  while (k < size) {
    val t = arr[i + k]
    arr[i + k] = arr[j + k]
    arr[j + k] = t
    k += 2
  }
}

fun rotateShuffled(arr: Array<Int>, mid0: Int, leftLen0: Int, rightLen0: Int) {
  var mid = mid0
  var leftLen = leftLen0
  var rightLen = rightLen0
  while (leftLen > 0 && rightLen > 0) {
    if (leftLen > rightLen) {
      rotateShuffledEqual(arr, mid - rightLen, mid, rightLen)
      mid -= rightLen
      leftLen -= rightLen
    } else {
      rotateShuffledEqual(arr, mid - leftLen, mid, leftLen)
      mid += leftLen
      rightLen -= leftLen
    }
  }
}

fun rotateShuffledOuter(arr: Array<Int>, mid0: Int, leftLen0: Int, rightLen0: Int) {
  var mid = mid0
  var leftLen = leftLen0
  var rightLen = rightLen0
  if (leftLen > rightLen) {
    rotateShuffledEqual(arr, mid - rightLen, mid + 1, rightLen)
    mid -= rightLen
    leftLen -= rightLen
    rotateShuffled(arr, mid, leftLen, rightLen)
  } else {
    rotateShuffledEqual(arr, mid - leftLen, mid + 1, leftLen)
    mid += leftLen + 1
    rightLen -= leftLen
    rotateShuffled(arr, mid, leftLen, rightLen)
  }
}

// The inverse of shuffleBlock: walks the same cycles, writing each value one step backward.
fun unshuffleBlock(arr: Array<Int>, start: Int, size: Int) {
  var i = 1
  while (i < size) {
    var prev = i
    val val0 = arr[start + i - 1]
    var j = (i * 2) % size
    while (j != i) {
      arr[start + prev - 1] = arr[start + j - 1]
      prev = j
      j = (j * 2) % size
    }
    arr[start + prev - 1] = val0
    i *= 3
  }
}

fun unshuffle(arr: Array<Int>, start0: Int, end: Int) {
  var start = start0
  while (end - start > 1) {
    val half = (end - start) / 2
    var chunk = 1
    while (chunk * 3 - 1 <= 2 * half) {
      chunk *= 3
    }
    val tail = (chunk - 1) / 2
    rotateShuffledOuter(arr, start + 2 * tail, 2 * tail, 2 * half - 2 * tail)
    unshuffleBlock(arr, start, chunk)
    start += chunk - 1
  }
}

fun compare3(arr: Array<Int>, i: Int, j: Int): Int {
  if (arr[i] < arr[j]) return -1
  return if (arr[i] == arr[j]) 0 else 1
}

// Scans the shuffled (interleaved) range one adjacent pair at a time. A pair already in order
// just advances the scan; a stretch of same-side elements gets un-shuffled back into two short
// plain runs and rotated into its final position.
fun mergeUp(arr: Array<Int>, start: Int, end: Int, fromLeft0: Boolean) {
  var i = start
  var j = i + 1
  var fromLeft = fromLeft0
  while (j < end) {
    val cmp = compare3(arr, i, j)
    if (cmp == -1 || (!fromLeft && cmp == 0)) {
      i++
      if (i == j) {
        j++
        fromLeft = !fromLeft
      }
    } else if (end - j == 1) {
      rotate(arr, j, j - i, 1)
      break
    } else {
      var run = 0
      if (fromLeft) {
        while (j + 2 * run < end && compare3(arr, j + 2 * run, i) != 1) {
          run++
        }
      } else {
        while (j + 2 * run < end && compare3(arr, j + 2 * run, i) == -1) {
          run++
        }
      }
      j--
      unshuffle(arr, j, j + 2 * run)
      rotate(arr, j, j - i, run)
      i += run + 1
      j += 2 * run + 1
    }
  }
}

fun merge(arr: Array<Int>, start: Int, mid: Int, end: Int) {
  if (mid - start <= end - mid) {
    shuffle(arr, start, end)
    mergeUp(arr, start, end, true)
  } else {
    shuffle(arr, start + 1, end)
    mergeUp(arr, start, end, false)
  }
}

fun ceilPow2(x0: Int): Int {
  var x = x0 - 1
  var shift = 16
  while (shift > 0) {
    x = x or (x shr shift)
    shift = shift shr 1
  }
  return x + 1
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) {
    return
  }

  var subarrayCount = ceilPow2(n)
  while (subarrayCount > 1) {
    var i = 0
    while (i < subarrayCount) {
      val lo = n * i / subarrayCount
      val mid = n * (i + 1) / subarrayCount
      val hi = n * (i + 2) / subarrayCount
      merge(arr, lo, mid, hi)
      i += 2
    }
    subarrayCount = subarrayCount shr 1
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
