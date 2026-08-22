// A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a recursive sort of its
// own, so its real cost grows worse than n! squared -- even a handful of elements can take an
// unreasonable amount of time. To keep this example runnable, the true recursive algorithm below
// is only ever applied to a small leading slice of the array (CHAOS_LIMIT elements); the rest is
// finished with an ordinary insertion sort, and the two already-sorted pieces are merged back
// together at the end. The random reshuffle is also replaced with a deterministic, never-repeating
// permutation walk, so neither piece can wander into an unbounded random search.
const val CHAOS_LIMIT = 5

// Advances arr to its next lexicographic permutation in place. Returns false (after resetting
// arr to its first, fully ascending permutation) once every arrangement has been visited -- a
// deterministic stand-in for "shuffle the array at random".
fun nextPermutation(arr: Array<Int>): Boolean {
  val n = arr.size
  var i = n - 2
  while (i >= 0 && arr[i] >= arr[i + 1]) {
    i--
  }
  if (i < 0) {
    arr.reverse()
    return false
  }
  var j = n - 1
  while (arr[j] <= arr[i]) {
    j--
  }
  val t = arr[i]
  arr[i] = arr[j]
  arr[j] = t
  var lo = i + 1
  var hi = n - 1
  while (lo < hi) {
    val tmp = arr[lo]
    arr[lo] = arr[hi]
    arr[hi] = tmp
    lo++
    hi--
  }
  return true
}

// The heart of the joke: rather than scanning arr once, decide whether it is sorted by copying
// it, recursively Bogo-Bogo-sorting the copy's first n - 1 elements with this exact same process
// one level down, reshuffling the whole copy until its last two elements land in order, and
// comparing the result against the original. A match means the copy is now the true sorted
// arrangement of the same values, which is only possible if arr was already sorted.
fun bogoBogoIsSorted(arr: Array<Int>): Boolean {
  val n = arr.size
  if (n <= 1) {
    return true
  }
  val copy = arr.copyOf()
  var prefix = copy.copyOfRange(0, n - 1)
  bogoBogoSort(prefix)
  prefix.copyInto(copy, 0, 0, n - 1)
  var candidate = 0
  while (copy[n - 2] > copy[n - 1]) {
    val t = copy[candidate]
    copy[candidate] = copy[n - 1]
    copy[n - 1] = t
    candidate++
    prefix = copy.copyOfRange(0, n - 1)
    bogoBogoSort(prefix)
    prefix.copyInto(copy, 0, 0, n - 1)
  }
  return copy.contentEquals(arr)
}

fun bogoBogoSort(arr: Array<Int>) {
  while (!bogoBogoIsSorted(arr)) {
    nextPermutation(arr)
  }
}

fun insertionSort(arr: Array<Int>) {
  for (i in 1 until arr.size) {
    val key = arr[i]
    var j = i - 1
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j]
      j--
    }
    arr[j + 1] = key
  }
}

fun mergeSorted(a: Array<Int>, b: Array<Int>): Array<Int> {
  val merged = ArrayList<Int>(a.size + b.size)
  var i = 0
  var j = 0
  while (i < a.size && j < b.size) {
    if (a[i] <= b[j]) {
      merged.add(a[i])
      i++
    } else {
      merged.add(b[j])
      j++
    }
  }
  while (i < a.size) {
    merged.add(a[i])
    i++
  }
  while (j < b.size) {
    merged.add(b[j])
    j++
  }
  return merged.toTypedArray()
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  val limit = minOf(CHAOS_LIMIT, n)
  val chaos = arr.copyOfRange(0, limit)
  val rest = arr.copyOfRange(limit, n)

  bogoBogoSort(chaos) // the real, recursive-check algorithm -- kept tiny on purpose
  insertionSort(rest) // an ordinary fast sort for the rest of the array

  val merged = mergeSorted(chaos, rest)
  merged.copyInto(arr)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
