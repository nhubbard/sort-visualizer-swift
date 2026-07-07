const val SIZE_THRESHOLD = 16

fun swap(arr: Array<Int>, a: Int, b: Int) {
  val t = arr[a]
  arr[a] = arr[b]
  arr[b] = t
}

fun medianOf3(arr: Array<Int>, left: Int, mid: Int, right: Int): Int {
  if (!(arr[left] >= arr[right])) {
    swap(arr, left, right)
  }
  if (!(arr[left] >= arr[mid])) {
    swap(arr, left, mid)
  }
  if (!(arr[mid] >= arr[right])) {
    swap(arr, mid, right)
  }
  return mid
}

fun partition(arr: Array<Int>, lo: Int, hi: Int, pivotValue: Int): Int {
  var i = lo
  var j = hi
  while (true) {
    while (arr[i] < pivotValue) i++
    j--
    while (pivotValue < arr[j]) j--
    if (!(i < j)) return i
    swap(arr, i, j)
    i++
  }
}

fun siftDown(arr: Array<Int>, lo: Int, rootStart: Int, rangeSize: Int) {
  var root = rootStart
  while (true) {
    var largest = root
    val left = 2 * root + 1
    val right = 2 * root + 2
    if (left < rangeSize && arr[lo + largest] < arr[lo + left]) largest = left
    if (right < rangeSize && arr[lo + largest] < arr[lo + right]) largest = right
    if (largest == root) break
    swap(arr, lo + root, lo + largest)
    root = largest
  }
}

fun heapSortRange(arr: Array<Int>, lo: Int, hi: Int) {
  val size = hi - lo
  for (i in size / 2 - 1 downTo 0) siftDown(arr, lo, i, size)
  for (end in size - 1 downTo 1) {
    swap(arr, lo, lo + end)
    siftDown(arr, lo, 0, end)
  }
}

fun insertionSort(arr: Array<Int>, start: Int, end: Int) {
  for (i in start + 1 until end) {
    var j = i
    while (j > start && arr[j] < arr[j - 1]) {
      swap(arr, j - 1, j)
      j--
    }
  }
}

fun floorLog2(a: Int): Int {
  return Math.floor(Math.log(a.toDouble()) / Math.log(2.0)).toInt()
}

fun introsortLoop(arr: Array<Int>, lo: Int, hiStart: Int, depthLimitStart: Int) {
  var hi = hiStart
  var depthLimit = depthLimitStart
  while (hi - lo > SIZE_THRESHOLD) {
    if (depthLimit == 0) {
      heapSortRange(arr, lo, hi)
      return
    }
    depthLimit--
    val mid = lo + (hi - lo) / 2
    val pivotIndex = medianOf3(arr, lo, mid, hi - 1)
    val pivotValue = arr[pivotIndex]
    val p = partition(arr, lo, hi, pivotValue)
    introsortLoop(arr, p, hi, depthLimit)
    hi = p
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  introsortLoop(arr, 0, n, 2 * floorLog2(n))
  insertionSort(arr, 0, n)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
