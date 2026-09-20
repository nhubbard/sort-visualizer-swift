fun multiSwap(arr: Array<Int>, a: Int, b: Int, count: Int) {
  for (i in 0 until count) {
    arr[a + i] = arr[b + i].also { arr[b + i] = arr[a + i] }
  }
}

fun rotate(arr: Array<Int>, pos: Int, lenA: Int, lenB: Int) {
  var p = pos
  var la = lenA
  var lb = lenB
  while (la != 0 && lb != 0) {
    if (la <= lb) {
      multiSwap(arr, p, p + la, la)
      p += la
      lb -= la
    } else {
      multiSwap(arr, p + (la - lb), p + la, lb)
      la -= lb
    }
  }
}

fun binSearch(arr: Array<Int>, pos: Int, len: Int, keyPos: Int, isLeft: Boolean): Int {
  var left = 0
  var right = len
  while (left < right) {
    val mid = left + (right - left) / 2
    val cond = if (isLeft) arr[pos + mid] < arr[keyPos] else arr[pos + mid] <= arr[keyPos]
    if (cond) left = mid + 1 else right = mid
  }
  return left
}

fun mergeWithoutBuffer(arr: Array<Int>, start: Int, leftLength: Int, rightLength: Int) {
  var pos = start
  var len1 = leftLength
  var len2 = rightLength
  if (len1 < len2) {
    while (len1 != 0) {
      val loc = binSearch(arr, pos + len1, len2, pos, true)
      if (loc != 0) { rotate(arr, pos, len1, loc); pos += loc; len2 -= loc }
      if (len2 == 0) break
      do { pos++; len1-- } while (len1 != 0 && arr[pos] <= arr[pos + len1])
    }
  } else {
    while (len2 != 0) {
      val loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false)
      if (loc != len1) { rotate(arr, pos + loc, len1 - loc, len2); len1 = loc }
      if (len1 == 0) break
      do { len2-- } while (len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1])
    }
  }
}

fun findRun(arr: Array<Int>, a: Int, b: Int): Int {
  var i = a + 1
  if (i == b) return i
  if (arr[i - 1] > arr[i]) {
    i++
    while (i < b && arr[i - 1] > arr[i]) i++
    var lo = a
    var hi = i - 1
    while (lo < hi) {
      arr[lo] = arr[hi].also { arr[hi] = arr[lo] }
      lo++
      hi--
    }
  } else {
    i++
    while (i < b && arr[i - 1] <= arr[i]) i++
  }
  return i
}

fun insert1(arr: Array<Int>, a: Int, l: Int) {
  val tmp = arr[l]
  var i = l - 1
  while (i >= a && arr[i] > tmp) {
    arr[i + 1] = arr[i]
    i--
  }
  arr[i + 1] = tmp
}

fun insert2(arr: Array<Int>, a: Int, l: Int, r: Int) {
  val tmpL = arr[l]
  val tmpR = arr[r]
  var i = l - 1
  while (i >= a && arr[i] > tmpR) {
    arr[i + 2] = arr[i]
    i--
  }
  arr[i + 2] = tmpR
  while (i >= a && arr[i] > tmpL) {
    arr[i + 1] = arr[i]
    i--
  }
  arr[i + 1] = tmpL
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  var i = findRun(arr, 0, n)
  while (i < n) {
    val j = findRun(arr, i, n)
    val len = j - i
    if (len == 1) insert1(arr, 0, i)
    else if (len == 2) insert2(arr, 0, i, i + 1)
    else mergeWithoutBuffer(arr, 0, i, len)
    i = j
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
