fun binarySearch(arr: IntArray, item: Int, start: Int, end: Int): Int {
  var lo = start
  var hi = end
  while (lo < hi) {
    val mid = lo + (hi - lo) / 2
    if (item < arr[mid]) {
      hi = mid
    } else {
      lo = mid + 1
    }
  }
  return lo
}

fun binaryInsertionSort(arr: IntArray, start: Int, end: Int) {
  for (i in start + 1 until end) {
    val item = arr[i]
    val pos = binarySearch(arr, item, start, i)
    var j = i
    while (j > pos) {
      arr[j] = arr[j - 1]
      j--
    }
    arr[pos] = item
  }
}

fun rebalance(arr: IntArray, temp: IntArray, counts: IntArray, locations: IntArray, spineSize: Int, batchEnd: Int) {
  for (i in 0 until spineSize) {
    counts[i + 1] = counts[i + 1] + counts[i] + 1
  }

  var k = 0
  for (i in spineSize until batchEnd) {
    val gap = locations[k]
    val position = counts[gap]
    temp[position] = arr[i]
    counts[gap] = position + 1
    k++
  }

  for (i in 0 until spineSize) {
    val position = counts[i]
    temp[position] = arr[i]
    counts[i] = position + 1
  }

  for (i in 0 until batchEnd) {
    arr[i] = temp[i]
  }

  binaryInsertionSort(arr, 0, counts[0] - 1)
  for (i in 0 until spineSize - 1) {
    binaryInsertionSort(arr, counts[i], counts[i + 1] - 1)
  }
  binaryInsertionSort(arr, counts[spineSize - 1], counts[spineSize])

  for (i in 0 until spineSize + 2) {
    counts[i] = 0
  }
}

fun librarySort(arr: IntArray) {
  val n = arr.size
  if (n < 2) {
    return
  }

  val rebalanceFactor = 2
  var spineSize = 1
  binaryInsertionSort(arr, 0, spineSize)

  var maxLevel = spineSize
  while (maxLevel * rebalanceFactor < n) {
    maxLevel *= rebalanceFactor
  }

  val temp = IntArray(n)
  val counts = IntArray(maxLevel + 2)
  val locations = IntArray(n)

  var i = spineSize
  var k = 0
  while (i < n) {
    if (rebalanceFactor * spineSize == i) {
      rebalance(arr, temp, counts, locations, spineSize, i)
      spineSize = i
      k = 0
    }
    val gap = binarySearch(arr, arr[i], 0, spineSize)
    counts[gap + 1]++
    locations[k] = gap
    k++
    i++
  }
  rebalance(arr, temp, counts, locations, spineSize, n)
}

fun sort(arr: IntArray) {
  librarySort(arr)
}

fun main() {
  var array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
