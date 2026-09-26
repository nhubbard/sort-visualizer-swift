private class CircularGrailSort(
  private val items: Array<Int>,
) {
  private val count = items.size

  private fun swap(a: Int, b: Int) {
    val x = a % count
    val y = b % count
    val temp = items[x]
    items[x] = items[y]
    items[y] = temp
  }

  private fun shiftForward(start: Int, midpoint: Int, end: Int) {
    var a = start
    var middle = midpoint
    while (middle < end) swap(a++, middle++)
  }

  private fun shiftBackward(start: Int, midpoint: Int, finish: Int) {
    var middle = midpoint
    var end = finish
    while (middle > start) swap(--end, --middle)
  }

  private fun insertion(start: Int, end: Int) {
    for (first in start + 1 until end) {
      var i = first
      while (i > start && items[(i - 1) % count] > items[i % count]) swap(i, --i)
    }
  }

  private fun multiSwap(a: Int, b: Int, length: Int) {
    for (i in 0 until length) swap(a + i, b + i)
  }

  private fun rotate(begin: Int, midpoint: Int, finish: Int) {
    var start = begin
    var middle = midpoint
    var end = finish
    var left = middle - start
    var right = end - middle
    while (left > 0 && right > 0) {
      if (right < left) {
        multiSwap(middle - right, middle, right)
        end -= right
        middle -= right
        left -= right
      } else {
        multiSwap(start, middle, left)
        start += left
        middle += left
        right -= left
      }
    }
  }

  private fun inPlaceMerge(start: Int, midpoint: Int, end: Int) {
    var i = start
    var middle = midpoint
    while (i < middle && middle < end) {
      if (items[i % count] > items[middle % count]) {
        var k = middle + 1
        while (k < end && items[i % count] > items[k % count]) k++
        rotate(i, middle, k)
        i += k - middle
        middle = k
      } else {
        i++
      }
    }
  }

  private fun merge(position: Int, start: Int, middle: Int, end: Int, full: Boolean): Int {
    var p = position
    var i = start
    var j = middle
    while (i < middle && j < end) {
      if (items[i % count] <= items[j % count]) swap(p++, i++) else swap(p++, j++)
    }
    if (i < middle) {
      if (i > p) shiftForward(p, i, middle)
    } else if (full) shiftForward(p, j, end)
    return if (i < middle) i else j
  }

  private fun blockLess(a: Int, b: Int, length: Int): Boolean {
    if (items[a % count] != items[b % count]) return items[a % count] < items[b % count]
    return items[(a + length - 1) % count] < items[(b + length - 1) % count]
  }

  private fun blockMerge(start: Int, middle: Int, end: Int, length: Int) {
    val b1 = end - (end - middle - 1) % length - 1
    if (b1 <= middle) {
      merge(start - length, start, middle, end, true)
      return
    }
    var b2 = b1
    var i = middle - length
    while (i > start && blockLess(b1, i, length)) {
      i -= length
      b2 -= length
    }
    var j = start
    while (j < b1 - length) {
      var minimum = j
      i = j + length
      while (i < b1) {
        if (blockLess(i, minimum, length)) minimum = i
        i += length
      }
      if (minimum != j) multiSwap(j, minimum, length)
      j += length
    }
    var frontier = start
    i = start + length
    while (i < b2) {
      frontier = merge(frontier - length, frontier, i, i + length, false)
      if (frontier < i) {
        shiftBackward(frontier, i, i + length)
        frontier += length
      }
      i += length
    }
    merge(frontier - length, frontier, b1, end, true)
  }

  fun run() {
    if (count < 2) return
    if (count <= 16) {
      insertion(0, count)
      return
    }
    var block = 1
    while (block * block < count) block *= 2
    var i = block
    var run = 1
    val rolling = count - block
    var end = count
    while (run <= block) {
      while (i + 2 * run < end) {
        merge(i - run, i, i + run, i + 2 * run, true)
        i += 2 * run
      }
      if (i + run < end) merge(i - run, i, i + run, end, true) else shiftForward(i - run, i, end)
      i = end + block - run
      end = i + rolling
      run *= 2
    }
    while (run < rolling) {
      while (i + 2 * run < end) {
        blockMerge(i, i + run, i + 2 * run, block)
        i += 2 * run
      }
      if (i + run < end) blockMerge(i, i + run, end, block) else shiftForward(i - block, i, end)
      i = end
      end += rolling
      run *= 2
    }
    insertion(i - block, i)
    inPlaceMerge(i - block, i, end)
    rotate(0, (i - block) % count, count)
  }
}

fun sort(array: Array<Int>) = CircularGrailSort(array).run()

fun main() {
  val array = arrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[${array.joinToString(", ")}]")
}
