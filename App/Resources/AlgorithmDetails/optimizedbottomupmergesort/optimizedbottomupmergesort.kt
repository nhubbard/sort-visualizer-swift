const val BLOCK_SIZE = 16

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

fun merge(src: Array<Int>, dst: Array<Int>, low: Int, mid: Int, high: Int) {
  var i = low
  var j = mid
  var k = low
  while (i < mid && j < high) {
    if (src[i] <= src[j]) {
      dst[k++] = src[i++]
    } else {
      dst[k++] = src[j++]
    }
  }
  while (i < mid) {
    dst[k++] = src[i++]
  }
  while (j < high) {
    dst[k++] = src[j++]
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < BLOCK_SIZE) {
    binaryInsertionSort(arr, 0, n)
    return
  }

  // Pre-pass: sort fixed-size blocks with binary insertion sort so the merge phase can
  // start from already-sorted runs instead of single elements.
  var low = 0
  while (low < n) {
    binaryInsertionSort(arr, low, minOf(low + BLOCK_SIZE, n))
    low += BLOCK_SIZE
  }

  // Merge phase: ping-pong between arr and scratch, alternating direction every pass,
  // instead of always merging into scratch and copying the whole buffer back.
  var src = arr
  var dst = Array(n) { 0 }
  var width = BLOCK_SIZE
  var passes = 0
  while (width < n) {
    low = 0
    while (low < n) {
      val mid = minOf(low + width, n)
      val high = minOf(low + 2 * width, n)
      if (mid < high) {
        merge(src, dst, low, mid, high)
      } else {
        for (i in low until mid) {
          dst[i] = src[i]
        }
      }
      low += 2 * width
    }
    val t = src
    src = dst
    dst = t
    width *= 2
    passes++
  }

  // An even number of passes lands the sorted result back in arr on its own; an odd
  // number leaves it in scratch, needing this one explicit copy back.
  if (passes % 2 == 1) {
    for (i in 0 until n) {
      arr[i] = src[i]
    }
  }
}

fun main() {
  var array = arrayOf<Int>(
    81, 14, 3, 94, 35, 31, 28, 17, 94, 13, 86, 94, 69, 11, 75, 54,
    4, 3, 11, 27, 29, 64, 77, 3, 71, 25, 91, 83, 89, 69, 53, 28,
    57, 75, 35, 0, 97, 20, 89, 54,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
