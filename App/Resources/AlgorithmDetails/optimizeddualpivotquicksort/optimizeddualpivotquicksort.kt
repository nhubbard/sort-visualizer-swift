const val INSERTION_THRESHOLD = 24

// Once a range's "between the pivots" middle partition holds more than this fraction of the
// range, it's worth pausing to scan out any elements that exactly equal one of the two pivots
// before recursing into what's left.
const val EQUAL_ELEMENTS_MIN_FRACTION = 4

// Sorts arr[low..high] in place (both bounds inclusive).
fun insertionSort(arr: Array<Int>, low: Int, high: Int) {
  for (i in (low + 1)..high) {
    val key = arr[i]
    var j = i - 1
    while (j >= low && arr[j] > key) {
      arr[j + 1] = arr[j]
      j--
    }
    arr[j + 1] = key
  }
}

// arr[low..high] holds only values in the closed range [pivot1, pivot2]. In a single scan,
// moves every element equal to pivot1 to the front and every element equal to pivot2 to the
// back -- a Dutch-national-flag-style three-way partition, generalized to two specific target
// values instead of "less than/greater than a pivot". Returns a pair of the inclusive bounds
// of what's left strictly between the two pivots.
fun movePivotDuplicatesOut(arr: Array<Int>, low: Int, high: Int, pivot1: Int, pivot2: Int): Pair<Int, Int> {
  var writeLow = low
  var read = low
  var writeHigh = high
  while (read <= writeHigh) {
    if (arr[read] == pivot1) {
      val t = arr[read]
      arr[read] = arr[writeLow]
      arr[writeLow] = t
      writeLow++
      read++
    } else if (arr[read] == pivot2) {
      val t = arr[read]
      arr[read] = arr[writeHigh]
      arr[writeHigh] = t
      writeHigh--
    } else {
      read++
    }
  }
  return Pair(writeLow, writeHigh)
}

// Sorts arr[low..high] in place (both bounds inclusive).
fun optimizedDualPivotQuickSort(arr: Array<Int>, low: Int, high: Int) {
  val size = high - low + 1
  if (size <= INSERTION_THRESHOLD) {
    if (size > 1) {
      insertionSort(arr, low, high)
    }
    return
  }

  // Sample two candidates roughly a third of the way in from each end and seed the two
  // pivots from them, smaller one first.
  val third = size / 3
  val pivot1Index = low + third
  val pivot2Index = high - third
  if (arr[pivot1Index] > arr[pivot2Index]) {
    val t = arr[pivot1Index]
    arr[pivot1Index] = arr[pivot2Index]
    arr[pivot2Index] = t
  }
  val t1 = arr[low]
  arr[low] = arr[pivot1Index]
  arr[pivot1Index] = t1
  val t2 = arr[high]
  arr[high] = arr[pivot2Index]
  arr[pivot2Index] = t2
  val pivot1 = arr[low]
  val pivot2 = arr[high]

  // Single left-to-right scan splitting the interior into three regions: less than pivot1,
  // between the two pivots, and greater than pivot2.
  var less = low + 1
  var great = high - 1
  var k = less
  while (k <= great) {
    if (arr[k] < pivot1) {
      val t = arr[k]
      arr[k] = arr[less]
      arr[less] = t
      less++
    } else if (arr[k] > pivot2) {
      while (k < great && arr[great] > pivot2) {
        great--
      }
      val t = arr[k]
      arr[k] = arr[great]
      arr[great] = t
      great--
      if (arr[k] < pivot1) {
        val t3 = arr[k]
        arr[k] = arr[less]
        arr[less] = t3
        less++
      }
    }
    k++
  }

  // Drop the two pivots into place at the boundaries of their regions.
  less--
  great++
  val t3 = arr[low]
  arr[low] = arr[less]
  arr[less] = t3
  val t4 = arr[high]
  arr[high] = arr[great]
  arr[great] = t4

  // arr[low..less-1] < pivot1, arr[less] == pivot1, arr[less+1..great-1] is the middle
  // region, arr[great] == pivot2, arr[great+1..high] > pivot2.
  optimizedDualPivotQuickSort(arr, low, less - 1)
  optimizedDualPivotQuickSort(arr, great + 1, high)

  var middleLow = less + 1
  var middleHigh = great - 1

  if (pivot1 != pivot2 && middleHigh >= middleLow) {
    val middleSize = middleHigh - middleLow + 1
    // Equal-elements optimization: a middle region this large is usually full of values tied
    // to one pivot or the other, which would otherwise get pointlessly re-partitioned by the
    // recursive call below. Shrink it first by scanning out the exact duplicates. They're
    // already correctly positioned relative to the low and high regions -- every pivot1
    // duplicate is >= everything already sorted into the low region, and every pivot2
    // duplicate is <= everything already sorted into the high region -- so neither of those
    // two regions needs to be touched again.
    if (middleSize > size / EQUAL_ELEMENTS_MIN_FRACTION) {
      val bounds = movePivotDuplicatesOut(arr, middleLow, middleHigh, pivot1, pivot2)
      middleLow = bounds.first
      middleHigh = bounds.second
    }
  }

  if (pivot1 != pivot2 && middleHigh >= middleLow) {
    optimizedDualPivotQuickSort(arr, middleLow, middleHigh)
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  optimizedDualPivotQuickSort(arr, 0, n - 1)
}

fun main() {
  var array =
    arrayOf<Int>(
      55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
      21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
    )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
