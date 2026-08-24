const val INSERTION_THRESHOLD = 16

fun insertionSort(arr: Array<Int>, lo: Int, hi: Int) {
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

// Returns whichever of a, b, c indexes the middle value of the three.
fun medianOfThree(arr: Array<Int>, a: Int, b: Int, c: Int): Int {
  var lowIndex = a
  var midIndex = b
  if (arr[lowIndex] > arr[midIndex]) {
    val t = lowIndex
    lowIndex = midIndex
    midIndex = t
  }
  if (arr[midIndex] > arr[c]) {
    midIndex = c
    if (arr[lowIndex] > arr[midIndex]) {
      midIndex = lowIndex
    }
  }
  return midIndex
}

fun fluxSortRange(arr: Array<Int>, lo: Int, hi: Int, swap: Array<Int>) {
  val n = hi - lo
  if (n <= INSERTION_THRESHOLD) {
    insertionSort(arr, lo, hi)
    return
  }

  val mid = lo + n / 2
  val pivot = arr[medianOfThree(arr, lo, mid, hi - 1)]

  // Partition into arr (elements <= pivot) and swap (elements > pivot). Ties go to the
  // low side, which is what keeps the sort stable.
  var lowWrite = lo
  var highWrite = 0
  for (read in lo until hi) {
    val value = arr[read]
    if (value > pivot) {
      swap[highWrite] = value
      highWrite++
    } else {
      arr[lowWrite] = value
      lowWrite++
    }
  }

  for (i in 0 until highWrite) {
    arr[lowWrite + i] = swap[i]
  }

  if (lowWrite == hi) {
    // Every element in range was <= pivot -- a run of duplicates around the pivot value
    // can cause this. There's no split to recurse into, so finish directly.
    insertionSort(arr, lo, hi)
    return
  }

  fluxSortRange(arr, lo, lowWrite, swap)
  fluxSortRange(arr, lowWrite, hi, swap)
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  val swap = Array(n) { 0 }
  fluxSortRange(arr, 0, n, swap)
}

fun main() {
  var array = arrayOf<Int>(
    55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97,
    15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44, 12,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
