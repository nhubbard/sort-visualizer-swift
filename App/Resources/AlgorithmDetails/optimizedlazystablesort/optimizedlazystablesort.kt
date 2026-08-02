fun swap(arr: Array<Int>, a: Int, b: Int) {
  val t = arr[a]
  arr[a] = arr[b]
  arr[b] = t
}

fun multiSwap(arr: Array<Int>, a: Int, b: Int, count: Int) {
  for (i in 0 until count) swap(arr, a + i, b + i)
}

fun rotate(arr: Array<Int>, posArg: Int, lenAArg: Int, lenBArg: Int) {
  var pos = posArg
  var lenA = lenAArg
  var lenB = lenBArg
  while (lenA != 0 && lenB != 0) {
    if (lenA <= lenB) {
      multiSwap(arr, pos, pos + lenA, lenA)
      pos += lenA
      lenB -= lenA
    } else {
      multiSwap(arr, pos + (lenA - lenB), pos + lenA, lenB)
      lenA -= lenB
    }
  }
}

fun binSearch(arr: Array<Int>, pos: Int, len: Int, keyPos: Int, isLeft: Boolean): Int {
  var left = -1
  var right = len
  val key = arr[keyPos]
  while (left < right - 1) {
    val mid = left + (right - left) / 2
    val cond = if (isLeft) arr[pos + mid] >= key else arr[pos + mid] > key
    if (cond) right = mid else left = mid
  }
  return right
}

fun mergeWithoutBuffer(arr: Array<Int>, posArg: Int, len1Arg: Int, len2Arg: Int) {
  var pos = posArg
  var len1 = len1Arg
  var len2 = len2Arg
  if (len1 == 0 || len2 == 0) return
  if (len1 < len2) {
    while (len1 != 0) {
      val loc = binSearch(arr, pos + len1, len2, pos, true)
      if (loc != 0) {
        rotate(arr, pos, len1, loc)
        pos += loc
        len2 -= loc
      }
      if (len2 == 0) break
      do {
        pos++
        len1--
      } while (len1 != 0 && arr[pos] <= arr[pos + len1])
    }
  } else {
    while (len2 != 0) {
      val loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false)
      if (loc != len1) {
        rotate(arr, pos + loc, len1 - loc, len2)
        len1 = loc
      }
      if (len1 == 0) break
      do {
        len2--
      } while (len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1])
    }
  }
}

// Guard: a chunk of length <= 1 has nothing to compare. ArrayV's own source skips this
// check and unconditionally reads arr[a] / arr[a + 1], which crashes whenever chunking
// leaves a trailing 1-element chunk (e.g. n = 17 leaves a final [16, 17) chunk).
fun insertionSortChunk(arr: Array<Int>, a: Int, b: Int) {
  if (b - a <= 1) return
  var i = a + 1
  val descending = arr[i - 1] > arr[i]
  i++
  if (descending) {
    while (i < b && arr[i - 1] > arr[i]) i++
    var lo = a
    var hi = i - 1
    while (lo < hi) {
      swap(arr, lo, hi)
      lo++
      hi--
    }
  } else {
    while (i < b && arr[i - 1] <= arr[i]) i++
  }
  while (i < b) {
    val current = arr[i]
    var pos = i - 1
    while (pos >= a && arr[pos] > current) {
      arr[pos + 1] = arr[pos]
      pos--
    }
    arr[pos + 1] = current
    i++
  }
}

fun lazyStableSort(arr: Array<Int>, pos: Int, len: Int) {
  var dist = 0
  while (dist + 16 < len) {
    insertionSortChunk(arr, pos + dist, pos + dist + 16)
    dist += 16
  }
  if (dist < len) insertionSortChunk(arr, pos + dist, pos + len)

  var part = 16
  while (part < len) {
    var left = 0
    val right = len - 2 * part
    while (left <= right) {
      mergeWithoutBuffer(arr, pos + left, part, part)
      left += 2 * part
    }
    val rest = len - left
    if (rest > part) mergeWithoutBuffer(arr, pos + left, part, rest - part)
    part *= 2
  }
}

fun sort(arr: Array<Int>) {
  lazyStableSort(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
