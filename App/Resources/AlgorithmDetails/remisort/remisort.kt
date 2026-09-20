fun sort(a: Array<Int>) {
  val n = a.size
  if (n < 2) return
  var lo = 0
  var hi = minOf(n, 1291)
  while (lo < hi) {
    val m = (lo + hi) / 2
    if (m * m * m >= n) hi = m else lo = m + 1
  }
  val block = lo
  val runLength = block * block
  val runs = (n - 1) / runLength + 1
  val keys = IntArray(if (runs < 2) n else runLength) { it }

  fun greater(x: Int, y: Int, base: Int): Boolean =
    a[base + x] > a[base + y] || (a[base + x] == a[base + y] && x > y)

  fun tableSift(root: Int, length: Int, base: Int, initial: Int) {
    var j = root
    var item = initial
    while (2 * j + 1 < length) {
      j = 2 * j + 1
      if (j + 1 < length && greater(keys[j + 1], keys[j], base)) j++
    }
    while (j > root && greater(item, keys[j], base)) j = (j - 1) / 2
    while (j > root) {
      val previous = keys[j]
      keys[j] = item
      item = previous
      j = (j - 1) / 2
    }
    keys[root] = item
  }

  fun tableSort(start: Int, end: Int) {
    val length = end - start
    if (length < 2) return
    for (i in (length - 1) / 2 downTo 0) tableSift(i, length, start, keys[i])
    for (i in length - 1 downTo 1) {
      val item = keys[i]
      keys[i] = keys[0]
      tableSift(0, i, start, item)
    }
    for (i in 0 until length) {
      if (keys[i] == i) continue
      val held = a[start + i]
      var j = i
      var next = keys[i]
      do {
        a[start + j] = a[start + next]
        keys[j] = j
        j = next
        next = keys[next]
      } while (next != i)
      a[start + j] = held
      keys[j] = j
    }
  }
  if (runs < 2) {
    tableSort(0, n)
    return
  }
  val buffer = IntArray(runLength)
  val heap = IntArray(runs) { it }
  val position = IntArray(runs)
  val destination = IntArray(runs)
  for (run in 0 until runs) {
    val start = run * runLength
    tableSort(start, minOf(start + runLength, n))
    position[run] = start
    destination[run] = start
  }

  fun less(x: Int, y: Int): Boolean =
    a[position[x]] < a[position[y]] || (a[position[x]] == a[position[y]] && x < y)

  fun sift(item: Int, start: Int, size: Int) {
    var root = start
    while (2 * root + 2 < size) {
      val left = 2 * root + 1
      val child = if (less(heap[left], heap[left + 1])) left else left + 1
      if (!less(heap[child], item)) break
      heap[root] = heap[child]
      root = child
    }
    val left = 2 * root + 1
    if (left < size && less(heap[left], item)) {
      heap[root] = heap[left]
      root = left
    }
    heap[root] = item
  }
  for (i in (runs - 1) / 2 downTo 0) sift(heap[i], i, runs)
  var size = runs

  fun advance(run: Int) {
    position[run]++
    if (position[run] == minOf((run + 1) * runLength, n)) {
      size--
      sift(heap[size], 0, size)
    } else {
      sift(heap[0], 0, size)
    }
  }
  for (i in buffer.indices) {
    val run = heap[0]
    buffer[i] = a[position[run]]
    advance(run)
  }
  var t = 0
  var count = 0
  var cursor = 0
  while (position[cursor] - destination[cursor] < block) cursor++
  do {
    val run = heap[0]
    a[destination[cursor]] = a[position[run]]
    destination[cursor]++
    advance(run)
    count++
    if (count == block) {
      keys[t++] = if (cursor > 0) destination[cursor] / block - block - 1 else -1
      cursor = 0
      count = 0
      while (position[cursor] - destination[cursor] < block) cursor++
    }
  } while (size > 0)
  var end = n
  while (count > 0) {
    count--
    destination[cursor]--
    end--
    a[end] = a[destination[cursor]]
  }
  position[runs - 1] = end
  keys[keys.lastIndex] = -1
  t = 0
  while (keys[t] != -1) t++
  var source = 0
  for (run in 1 until runs) {
    if (source >= destination[0]) break
    while (destination[run] < position[run]) {
      keys[t++] = destination[run] / block - block
      while (keys[t] != -1) t++
      for (x in 0 until block) a[destination[run] + x] = a[source + x]
      destination[run] += block
      source += block
    }
  }
  for (x in buffer.indices) a[x] = buffer[x]
  val blocks = (end - runLength) / block
  for (i in 0 until blocks) {
    if (keys[i] == i) continue
    for (x in 0 until block) buffer[x] = a[runLength + i * block + x]
    var j = i
    var next = keys[i]
    do {
      for (x in 0 until block) a[runLength + j * block + x] = a[runLength + next * block + x]
      keys[j] = j
      j = next
      next = keys[next]
    } while (next != i)
    for (x in 0 until block) a[runLength + j * block + x] = buffer[x]
    keys[j] = j
  }
}

fun main() {
  val array = arrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
