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

fun sort(arr: Array<Int>) {
  val n = arr.size
  var dist = 1
  while (dist < n) {
    if (arr[dist - 1] > arr[dist]) {
      arr[dist - 1] = arr[dist].also { arr[dist] = arr[dist - 1] }
    }
    dist += 2
  }
  var part = 2
  while (part < n) {
    var left = 0
    val right = n - 2 * part
    while (left <= right) {
      mergeWithoutBuffer(arr, left, part, part)
      left += 2 * part
    }
    val rest = n - left
    if (rest > part) mergeWithoutBuffer(arr, left, part, rest - part)
    part *= 2
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
