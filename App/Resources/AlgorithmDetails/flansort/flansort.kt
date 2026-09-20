private class Flan(
  private val a: Array<Int>,
) {
  private val gap = 14
  private val ratio = 4
  private val position = IntArray(gap + 2)
  private val heap = IntArray(gap + 2)
  private var random = 0x9e3779b97f4a7c15UL

  init {
    for (value in a) {
      random = (random xor value.toLong().toULong()) * 0xbf58476d1ce4e5b9UL + 0x94d049bb133111ebUL
    }
  }

  private fun choice(count: Int): Int {
    random = random xor (random shr 12)
    random = random xor (random shl 25)
    random = random xor (random shr 27)
    return ((random * 0x2545f4914f6cdd1dUL) % count.toULong()).toInt()
  }

  private fun swap(i: Int, j: Int) {
    val held = a[i]
    a[i] = a[j]
    a[j] = held
  }

  private fun median(i: Int, m: Int, j: Int): Int {
    if (a[m] > a[i]) {
      if (a[m] < a[j]) return m
      return if (a[i] > a[j]) i else j
    }
    if (a[m] > a[j]) return m
    return if (a[i] < a[j]) i else j
  }

  private fun ninther(start: Int, end: Int): Int {
    val step = (end - start) / 9
    return median(
      median(start, start + step, start + 2 * step),
      median(start + 3 * step, start + 4 * step, start + 5 * step),
      median(start + 6 * step, start + 7 * step, start + 8 * step),
    )
  }

  private fun pivot(start: Int, end: Int): Int {
    val step = (end - start) / 3
    return median(ninther(start, start + step), ninther(start + step, start + 2 * step), ninther(start + 2 * step, end))
  }

  private fun binarySearch(start: Int, end: Int, value: Int, backward: Boolean): Int {
    var low = start
    var high = end
    while (low < high) {
      val middle = low + (high - low) / 2
      val found = if (backward) a[middle] < value else a[middle] > value
      if (found) high = middle else low = middle + 1
    }
    return low
  }

  private fun insert(value: Int, start: Int, end: Int) {
    var i = start
    while (i > end) {
      i--
      a[i + 1] = a[i]
    }
    a[end] = value
  }

  private fun insertion(start: Int, end: Int) {
    for (i in start + 1 until end) {
      val value = a[i]
      insert(value, i, binarySearch(start, i, value, false))
    }
  }

  private fun blockSearch(start: Int, end: Int, value: Int, right: Boolean): Int {
    var low = start
    var high = end
    while (low < high) {
      val middle = low + ((high - low) / (gap + 1) / 2) * (gap + 1)
      val found = if (right) a[middle] > value else a[middle] >= value
      if (found) high = middle else low = middle + gap + 1
    }
    return low
  }

  private fun retrieve(end: Int, scratch: Int, pEnd: Int, boundary: Int, backward: Boolean) {
    var destination = end - 1
    var block = pEnd - (gap + 1)
    while (block > scratch + gap) {
      var item = binarySearch(block - gap, block, boundary, backward) - 1
      block -= gap + 1
      while (item >= block) {
        swap(destination, item)
        destination--
        item--
      }
    }
    var item = binarySearch(scratch, scratch + gap, boundary, backward) - 1
    while (item >= scratch) {
      swap(destination, item)
      destination--
      item--
    }
  }

  private fun librarySort(start: Int, end: Int, scratch: Int, boundary: Int, backward: Boolean) {
    val length = end - start
    if (length < 32) {
      insertion(start, end)
      return
    }
    var count = length
    while (count >= 32) count = (count - 1) / ratio + 1
    var i = start + count
    var trigger = start + ratio * count
    var pEnd = scratch + (count + 1) * (gap + 1) + gap
    insertion(start, i)
    for (k in 0 until count) swap(start + k, scratch + k * (gap + 1) + gap)
    while (i < end) {
      if (i == trigger) {
        retrieve(i, scratch, pEnd, boundary, backward)
        count = i - start
        pEnd = scratch + (count + 1) * (gap + 1) + gap
        trigger = start + (trigger - start) * ratio
        for (k in 0 until count) swap(start + k, scratch + k * (gap + 1) + gap)
      }
      val value = a[i]
      var block = blockSearch(scratch + gap, pEnd - (gap + 1), value, false)
      if (a[block] == value) {
        val afterEqual = blockSearch(block + gap + 1, pEnd - (gap + 1), value, true)
        block += choice((afterEqual - block) / (gap + 1)) * (gap + 1)
      }
      val loc = binarySearch(block - gap, block, boundary, backward)
      if (loc == block) {
        do {
          block += gap + 1
        }
        while (block < pEnd && binarySearch(block - gap, block, boundary, backward) == block)
        if (block == pEnd) {
          retrieve(i, scratch, pEnd, boundary, backward)
          count = i - start
          pEnd = scratch + (count + 1) * (gap + 1) + gap
          trigger = start + (trigger - start) * ratio
          for (k in 0 until count) swap(start + k, scratch + k * (gap + 1) + gap)
        } else {
          val first = binarySearch(block - gap, block, boundary, backward)
          val distance = block - maxOf(first, block - gap / 2)
          var source = block - distance
          var destination = block
          while (source > loc - distance) {
            source--
            destination--
            swap(destination, source)
          }
        }
      } else {
        val displaced = a[loc]
        a[i] = displaced
        i++
        insert(value, loc, binarySearch(block - gap, loc, value, false))
      }
    }
    retrieve(end, scratch, pEnd, boundary, backward)
  }

  private fun less(x: Int, y: Int): Boolean {
    val left = a[position[x]]
    val right = a[position[y]]
    return left < right || (left == right && x < y)
  }

  private fun sift(item: Int, start: Int, size: Int) {
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

  private fun merge(runLength: Int, end: Int, destination: Int, count: Int) {
    if (count < 2) {
      if (count == 1) {
        var target = destination
        while (position[0] < end) {
          swap(target, position[0])
          target++
          position[0]++
        }
      }
      return
    }
    val start = position[0]
    for (i in 0 until count) heap[i] = i
    for (i in (count - 1) / 2 downTo 0) sift(heap[i], i, count)
    var size = count
    var target = destination
    while (size > 0) {
      val run = heap[0]
      swap(target, position[run])
      target++
      position[run]++
      if (position[run] == minOf(start + (run + 1) * runLength, end)) {
        size--
        sift(heap[size], 0, size)
      } else {
        sift(heap[0], 0, size)
      }
    }
  }

  fun execute() {
    var start = 0
    var end = a.size
    while (end - start >= 32) {
      val pivotValue = a[pivot(start, end)]
      var first = start
      var i = start - 1
      var j = end
      var last = end
      while (true) {
        i++
        while (i < j) {
          if (a[i] == pivotValue) {
            swap(first, i)
            first++
          } else if (a[i] < pivotValue) break
          i++
        }
        j--
        while (j > i) {
          if (a[j] == pivotValue) {
            last--
            swap(last, j)
          } else if (a[j] > pivotValue) break
          j--
        }
        if (i < j) {
          swap(i, j)
        } else {
          if (first == end) return
          if (j < i) j++
          while (first > start) {
            i--
            first--
            swap(i, first)
          }
          while (last < end) {
            swap(j, last)
            j++
            last++
          }
          break
        }
      }
      var left = i - start
      var right = end - j
      var count = 0
      if (left <= right) {
        var move = end - left
        left = maxOf((right + 1) / (gap + 1), 16)
        var k = start
        while (k < i) {
          librarySort(k, minOf(k + left, i), j, pivotValue, true)
          position[count++] = k
          k += left
        }
        merge(left, i, move, count)
        if (j - i < move - j) {
          while (i < j) {
            move--
            swap(i, move)
            i++
          }
          end = move
        } else {
          while (move > j) {
            move--
            swap(i, move)
            i++
          }
          end = i
        }
      } else {
        var move = start + right
        right = maxOf((left + 1) / (gap + 1), 16)
        var k = j
        while (k < end) {
          librarySort(k, minOf(k + right, end), start, pivotValue, false)
          position[count++] = k
          k += right
        }
        merge(right, end, start, count)
        if (i - move < j - i) {
          while (move < i) {
            j--
            swap(move, j)
            move++
          }
          start = j
        } else {
          while (j > i) {
            j--
            swap(move, j)
            move++
          }
          start = move
        }
      }
    }
    insertion(start, end)
  }
}

fun sort(a: Array<Int>) {
  if (a.size > 1) Flan(a).execute()
}

fun main() {
  val array = arrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
