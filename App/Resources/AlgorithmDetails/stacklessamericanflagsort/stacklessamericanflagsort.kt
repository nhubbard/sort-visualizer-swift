const val RADIX = 4

fun getDigit(value: Int, place: Int): Int {
  var v = value
  for (p in 0 until place) {
    v /= RADIX
  }
  return v % RADIX
}

fun shift(value: Int, places: Int): Int {
  var v = value
  for (p in 0 until places) {
    v /= RADIX
  }
  return v
}

// Turns the raw per-bucket counts already accumulated in `counts` into
// starting offsets, then places every element in [start, end) by
// following displacement cycles, one bucket at a time.
fun distribute(
  arr: Array<Int>,
  counts: IntArray,
  offsets: IntArray,
  start: Int,
  end: Int,
  place: Int,
): Int {
  for (i in 1 until RADIX) {
    counts[i] += counts[i - 1]
    offsets[i] = counts[i - 1]
  }

  for (bucket in 0 until RADIX - 1) {
    val position = start + offsets[bucket]
    if (counts[bucket] > offsets[bucket]) {
      var held = arr[position]
      do {
        val digit = getDigit(held, place)
        counts[digit]--
        val displaced = arr[start + counts[digit]]
        arr[start + counts[digit]] = held
        held = displaced
      } while (counts[bucket] > offsets[bucket])
    }
  }

  val split = start + offsets[1]
  for (i in 0 until RADIX) {
    counts[i] = 0
    offsets[i] = 0
  }
  return split
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) {
    return
  }

  var q = 0
  var probe = RADIX
  val maxValue = arr.max()
  while (probe <= maxValue) {
    q++
    probe *= RADIX
  }

  val counts = IntArray(RADIX)
  val offsets = IntArray(RADIX)

  // i/b track the bounds of whichever range is currently active, q the
  // digit place being distributed on, and m a counter that mirrors how
  // many bucket boundaries have already been walked at the current depth,
  // standing in for the call stack a recursive walk would need.
  var m = 0
  var i = 0
  var b = n

  for (j in i until b) {
    counts[getDigit(arr[j], q)]++
  }

  while (i < n) {
    val p = if (b - i < 1) i else distribute(arr, counts, offsets, i, b, q)

    if (q == 0) {
      m += RADIX
      var t = m / RADIX
      while (t % RADIX == 0) {
        t /= RADIX
        q++
      }

      i = b
      while (b < n && shift(arr[b], q + 1) == shift(m, q + 1)) {
        counts[getDigit(arr[b], q)]++
        b++
      }
    } else {
      b = p
      q--
      for (j in i until b) {
        counts[getDigit(arr[j], q)]++
      }
    }
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
