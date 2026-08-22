// Reverses arr[0..hi] in place. This "flip" is the only move the algorithm ever performs; there
// is no per-element shift anywhere.
fun flip(arr: Array<Int>, hiIn: Int) {
  var lo = 0
  var hi = hiIn
  while (lo < hi) {
    val t = arr[lo]
    arr[lo] = arr[hi]
    arr[hi] = t
    lo++
    hi--
  }
}

// Monobound binary search: locates the index within the ascending run arr[start..end) at which
// arr[valueIndex] belongs, using one comparison per halving instead of the usual two.
fun searchAscending(arr: Array<Int>, start: Int, endIn: Int, valueIndex: Int): Int {
  var end = endIn
  var top = end - start
  while (top > 1) {
    val mid = top / 2
    if (arr[valueIndex] <= arr[end - mid]) {
      end -= mid
    }
    top -= mid
  }
  if (arr[valueIndex] <= arr[end - 1]) {
    return end - 1
  }
  return end
}

// Mirror image of searchAscending for a descending run arr[start..end).
fun searchDescending(arr: Array<Int>, startIn: Int, end: Int, valueIndex: Int): Int {
  var start = startIn
  var top = end - start
  while (top > 1) {
    val mid = top / 2
    if (arr[start + mid] > arr[valueIndex]) {
      start += mid
    }
    top -= mid
  }
  if (arr[start] > arr[valueIndex]) {
    return start + 1
  }
  return start
}

// Hand-sorts arr[0..n) for n <= 3 via a small decision tree. Returns true if the result runs
// ascending, false if it runs descending.
fun sortFirstThree(arr: Array<Int>, n: Int): Boolean {
  if (n < 2) {
    return false
  }
  if (arr[0] > arr[1]) {
    flip(arr, 1)
  }
  if (n > 2) {
    if (arr[1] > arr[2]) {
      if (arr[0] > arr[2]) {
        flip(arr, 1)
      } else {
        flip(arr, 2)
        flip(arr, 1)
      }
      return false
    }
    return true
  }
  return true
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) {
    return
  }

  var ascending = sortFirstThree(arr, n)

  for (i in 3 until n) {
    if (ascending) {
      if (arr[i - 1] <= arr[i]) {
        // Already fits; the ascending prefix already ends at or below the new element.
        continue
      }
      if (arr[0] > arr[i]) {
        // The new element is smaller than everything in the prefix -- one flip turns the whole
        // thing, including the new element, into a descending run.
        flip(arr, i - 1)
        ascending = false
        continue
      }
      val idx = searchAscending(arr, 0, i, i)
      flip(arr, i)
      val tail = i - idx
      flip(arr, tail)
      flip(arr, tail - 1)
      ascending = false
    } else {
      if (arr[i - 1] > arr[i]) {
        continue
      }
      if (arr[0] <= arr[i]) {
        flip(arr, i - 1)
        ascending = true
        continue
      }
      val idx = searchDescending(arr, 0, i, i)
      flip(arr, i)
      val tail = i - idx
      flip(arr, tail)
      flip(arr, tail - 1)
      ascending = true
    }
  }

  if (!ascending) {
    flip(arr, n - 1)
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
