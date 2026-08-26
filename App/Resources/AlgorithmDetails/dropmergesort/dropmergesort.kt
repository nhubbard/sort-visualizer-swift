const val RECENCY = 8
const val EARLY_OUT_TEST_AT = 4
const val EARLY_OUT_DISORDER_FRACTION = 0.6

// A plain general-purpose sort for arr[lo..hi), used both as the early-out fallback and to sort
// the leftover "dropped" elements before the final merge. Any decent O(n log n) sort works here
// -- the algorithm doesn't depend on which one.
fun quicksort(arr: MutableList<Int>, lo: Int, hi: Int) {
  if (hi - lo <= 1) return
  val pivot = arr[lo + (hi - lo) / 2]
  val less = mutableListOf<Int>()
  val equal = mutableListOf<Int>()
  val greater = mutableListOf<Int>()

  for (i in lo until hi) {
    if (arr[i] < pivot) {
      less.add(arr[i])
    } else if (arr[i] > pivot) {
      greater.add(arr[i])
    } else {
      equal.add(arr[i])
    }
  }

  quicksort(less, 0, less.size)
  quicksort(greater, 0, greater.size)

  var k = lo
  for (value in less) arr[k++] = value
  for (value in equal) arr[k++] = value
  for (value in greater) arr[k++] = value
}

fun sort(arr: MutableList<Int>) {
  val length = arr.size
  if (length < 2) return

  val dropped = mutableListOf<Int>()
  var numDroppedInARow = 0
  var read = 0
  var write = 0
  var iteration = 0
  val earlyOutStop = length / EARLY_OUT_TEST_AT

  while (read < length) {
    iteration++
    if (iteration == earlyOutStop && dropped.size > read * EARLY_OUT_DISORDER_FRACTION) {
      // Too disordered for the adaptive approach to be worth it: flush what's been dropped so
      // far back into the array and fall back to a plain full sort.
      for (value in dropped) {
        arr[write] = value
        write++
      }
      dropped.clear()
      quicksort(arr, 0, length)
      return
    }

    if (write == 0 || arr[read] >= arr[write - 1]) {
      // In order -- keep it.
      arr[write] = arr[read]
      write++
      read++
      numDroppedInARow = 0
    } else if (numDroppedInARow == 0 && write >= 2 && arr[read] >= arr[write - 2]) {
      // Quick undo: the element two back would have accepted this one just fine, so drop the
      // one right before it instead of the new element.
      dropped.add(arr[write - 1])
      arr[write - 1] = arr[read]
      read++
    } else if (numDroppedInARow < RECENCY) {
      dropped.add(arr[read])
      read++
      numDroppedInARow++
    } else {
      // Accepting something `numDroppedInARow` elements back made every subsequent element
      // drop -- that accept was a mistake. Undo it, and any other recently accepted elements
      // bigger than the dropped run's maximum.
      repeat(numDroppedInARow) { dropped.removeAt(dropped.size - 1) }
      read -= numDroppedInARow

      var numBacktracked = 1
      write--

      var maxOfDropped = arr[read]
      for (i in (read + 1)..(read + numDroppedInARow)) {
        if (arr[i] > maxOfDropped) maxOfDropped = arr[i]
      }

      while (write >= 1 && maxOfDropped < arr[write - 1]) {
        write--
        numBacktracked++
      }

      for (i in write until (write + numBacktracked)) {
        dropped.add(arr[i])
      }

      numDroppedInARow = 0
    }
  }

  for (offset in dropped.indices) {
    arr[write + offset] = dropped[offset]
  }

  quicksort(arr, write, length)

  // Copy the now-sorted dropped tail before the final backward merge starts overwriting
  // arr[write..] in place.
  val buffer = arr.subList(write, write + dropped.size).toList()

  var i = buffer.size - 1
  var j = write - 1
  var k = length - 1

  while (i >= 0) {
    if (j < 0 || buffer[i] > arr[j]) {
      arr[k] = buffer[i]
      k--
      i--
    } else {
      arr[k] = arr[j]
      k--
      j--
    }
  }
}

fun main() {
  val array =
    mutableListOf(
      0, 1, 2, 3, 4, 9, 6, 7, 8, 5, 10, 11, 12, 13, 14, 15,
      21, 17, 18, 19, 20, 16, 22, 23, 24, 28, 26, 27, 25, 29,
    )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
