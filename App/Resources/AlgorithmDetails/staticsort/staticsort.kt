fun findMinMax(array: IntArray, a: Int, b: Int): Pair<Int, Int> {
  var minValue = array[a]
  var maxValue = array[a]
  for (i in a + 1 until b) {
    if (array[i] < minValue) {
      minValue = array[i]
    } else if (array[i] > maxValue) {
      maxValue = array[i]
    }
  }
  return Pair(minValue, maxValue)
}

fun insertionSortRange(array: IntArray, s: Int, e: Int) {
  for (i in s + 1 until e) {
    var j = i
    while (j > s && array[j - 1] > array[j]) {
      val tmp = array[j - 1]
      array[j - 1] = array[j]
      array[j] = tmp
      j--
    }
  }
}

fun siftDown(array: IntArray, s: Int, root: Int, size: Int) {
  var root = root
  while (true) {
    var largest = root
    val left = 2 * root + 1
    val right = 2 * root + 2
    if (left < size && array[s + largest] < array[s + left]) {
      largest = left
    }
    if (right < size && array[s + largest] < array[s + right]) {
      largest = right
    }
    if (largest == root) break
    val tmp = array[s + root]
    array[s + root] = array[s + largest]
    array[s + largest] = tmp
    root = largest
  }
}

fun heapSortRange(array: IntArray, s: Int, e: Int) {
  val size = e - s
  if (size <= 1) return
  var i = size / 2 - 1
  while (i >= 0) {
    siftDown(array, s, i, size)
    i--
  }
  var end = size - 1
  while (end > 0) {
    val tmp = array[s]
    array[s] = array[s + end]
    array[s + end] = tmp
    siftDown(array, s, 0, end)
    end--
  }
}

fun classify(value: Int, minValue: Int, c: Double): Int {
  return ((value - minValue) * c).toInt()
}

fun staticSort(array: IntArray, a: Int, b: Int) {
  val (minValue, maxValue) = findMinMax(array, a, b)
  val auxLen = b - a
  val count = IntArray(auxLen + 1)
  val offset = IntArray(auxLen + 1)
  val c = auxLen.toDouble() / (maxValue - minValue + 1)

  for (i in a until b) {
    val idx = classify(array[i], minValue, c)
    count[idx] += 1
  }

  offset[0] = a
  for (i in 1 until auxLen) {
    offset[i] = count[i - 1] + offset[i - 1]
  }

  for (v in 0 until auxLen) {
    while (count[v] > 0) {
      val origin = offset[v]
      var from = origin
      var num = array[from]
      array[from] = -1
      do {
        val idx = classify(num, minValue, c)
        val to = offset[idx]
        offset[idx] += 1
        count[idx] -= 1
        val temp = array[to]
        array[to] = num
        num = temp
        from = to
      } while (from != origin)
    }
  }

  for (i in 0 until auxLen) {
    val s = if (i > 1) offset[i - 1] else a
    val e = offset[i]
    if (e - s <= 1) continue
    if (e - s > 16) {
      heapSortRange(array, s, e)
    } else {
      insertionSortRange(array, s, e)
    }
  }
}

fun sort(arr: IntArray) {
  if (arr.size > 1) {
    staticSort(arr, 0, arr.size)
  }
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
