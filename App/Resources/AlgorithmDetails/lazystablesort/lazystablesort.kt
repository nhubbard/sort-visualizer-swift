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

fun mergeWithoutBuffer(arr: Array<Int>, pos: Int, len1: Int, len2: Int) {
  if (len1 == 0 || len2 == 0) return
  if (len1 == 1) {
    val loc = binSearch(arr, pos + 1, len2, pos, true)
    rotate(arr, pos, 1, loc)
    return
  }
  if (len2 == 1) {
    val loc = binSearch(arr, pos, len1, pos + len1, false)
    rotate(arr, pos + loc, len1 - loc, 1)
    return
  }
  val mid1 = len1 / 2
  val loc = binSearch(arr, pos + len1, len2, pos + mid1, true)
  rotate(arr, pos + mid1, len1 - mid1, loc)
  mergeWithoutBuffer(arr, pos, mid1, loc)
  mergeWithoutBuffer(arr, pos + mid1 + loc, len1 - mid1, len2 - loc)
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
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
