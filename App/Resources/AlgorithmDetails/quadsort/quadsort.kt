const val INSERTION_RUN = 4

fun insertionSortRange(arr: Array<Int>, lo: Int, hi: Int) {
  for (i in lo + 1 until hi) {
    val key = arr[i]
    var j = i - 1
    while (j >= lo && arr[j] > key) {
      arr[j + 1] = arr[j]
      j--
    }
    arr[j + 1] = key
  }
}

// Merges the two equal-length sorted runs source[lo until lo+runLength] and
// source[lo+runLength until lo+2*runLength] into dest, filling from both ends toward the
// middle at once instead of scanning front to back alone.
fun parityMerge(source: Array<Int>, lo: Int, runLength: Int, dest: Array<Int>) {
  var left = lo
  var right = lo + runLength
  var leftEnd = lo + runLength - 1
  var rightEnd = lo + 2 * runLength - 1
  var front = lo
  var back = lo + 2 * runLength - 1

  for (step in 0 until runLength) {
    if (source[left] <= source[right]) {
      dest[front] = source[left]
      left++
    } else {
      dest[front] = source[right]
      right++
    }
    front++

    if (source[leftEnd] > source[rightEnd]) {
      dest[back] = source[leftEnd]
      leftEnd--
    } else {
      dest[back] = source[rightEnd]
      rightEnd--
    }
    back--
  }
}

fun mergeRange(source: Array<Int>, lo: Int, mid: Int, hi: Int, dest: Array<Int>) {
  var left = lo
  var right = mid
  var out = lo
  while (left < mid && right < hi) {
    if (source[left] <= source[right]) {
      dest[out] = source[left]
      left++
    } else {
      dest[out] = source[right]
      right++
    }
    out++
  }
  while (left < mid) {
    dest[out] = source[left]
    left++
    out++
  }
  while (right < hi) {
    dest[out] = source[right]
    right++
    out++
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  val buffer = arr.copyOf()

  var lo = 0
  while (lo < n) {
    insertionSortRange(arr, lo, minOf(lo + INSERTION_RUN, n))
    lo += INSERTION_RUN
  }

  var runLength = INSERTION_RUN
  while (runLength < n) {
    lo = 0
    while (lo < n) {
      val mid = minOf(lo + runLength, n)
      val hi = minOf(lo + runLength * 2, n)
      if (mid - lo == runLength && hi - mid == runLength) {
        parityMerge(arr, lo, runLength, buffer)
      } else if (mid < hi) {
        mergeRange(arr, lo, mid, hi, buffer)
      } else {
        for (i in lo until mid) {
          buffer[i] = arr[i]
        }
      }
      lo += runLength * 2
    }
    for (i in 0 until n) {
      arr[i] = buffer[i]
    }
    runLength *= 2
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
