fun hyperfloor(n: Int): Int {
  var power = 1
  while (power * 2 <= n) power *= 2
  return power
}

fun uncheckedInsertionSort(array: IntArray, first: Int, last: Int) {
  var cur = first + 1
  while (cur != last) {
    if (array[cur] < array[cur - 1]) {
      val tmp = array[cur]
      var sift = cur
      var sift1 = cur - 1
      while (true) {
        array[sift] = array[sift1]
        sift--
        if (sift == first) break
        sift1--
        if (tmp >= array[sift1]) break
      }
      array[sift] = tmp
    }
    cur++
  }
}

fun insertionSort(array: IntArray, first: Int, last: Int) {
  if (first == last) return
  uncheckedInsertionSort(array, first, last)
}

fun poplarSift(array: IntArray, firstIn: Int, sizeIn: Int) {
  var size = sizeIn
  if (size < 2) return
  var root = firstIn + (size - 1)
  var childRoot1 = root - 1
  var childRoot2 = firstIn + (size / 2 - 1)
  while (true) {
    var maxRoot = root
    if (array[maxRoot] < array[childRoot1]) maxRoot = childRoot1
    if (array[maxRoot] < array[childRoot2]) maxRoot = childRoot2
    if (maxRoot == root) return
    val temp = array[root]
    array[root] = array[maxRoot]
    array[maxRoot] = temp
    size /= 2
    if (size < 2) return
    root = maxRoot
    childRoot1 = root - 1
    childRoot2 = maxRoot - (size - size / 2)
  }
}

fun popHeapWithSize(array: IntArray, first: Int, last: Int, sizeIn: Int) {
  var size = sizeIn
  var poplarSize = hyperfloor(size + 1) - 1
  val lastRoot = last - 1
  var bigger = lastRoot
  var biggerSize = poplarSize

  var it = first
  while (true) {
    val root = it + poplarSize - 1
    if (root == lastRoot) break
    if (array[bigger] < array[root]) {
      bigger = root
      biggerSize = poplarSize
    }
    it = root + 1
    size -= poplarSize
    poplarSize = hyperfloor(size + 1) - 1
  }

  if (bigger != lastRoot) {
    val temp = array[bigger]
    array[bigger] = array[lastRoot]
    array[lastRoot] = temp
    poplarSift(array, bigger - (biggerSize - 1), biggerSize)
  }
}

fun makeHeap(array: IntArray, first: Int, last: Int) {
  val size = last - first
  if (size < 2) return
  val smallPoplarSize = 15
  if (size <= smallPoplarSize) {
    uncheckedInsertionSort(array, first, last)
    return
  }

  var poplarLevel = 1
  var it = first
  var next = it + smallPoplarSize
  while (true) {
    uncheckedInsertionSort(array, it, next)
    var poplarSize = smallPoplarSize
    var i = (poplarLevel and -poplarLevel) shr 1
    while (i != 0) {
      it -= poplarSize
      poplarSize = 2 * poplarSize + 1
      if (it + poplarSize > last) break
      poplarSift(array, it, poplarSize)
      next++
      i = i shr 1
    }
    if ((last - next) <= smallPoplarSize) {
      insertionSort(array, next, last)
      return
    }
    it = next
    next += smallPoplarSize
    poplarLevel++
  }
}

fun sortHeap(array: IntArray, first: Int, lastIn: Int) {
  var last = lastIn
  var size = last - first
  if (size < 2) return
  do {
    popHeapWithSize(array, first, last, size)
    last--
    size--
  } while (size > 1)
}

fun sort(array: IntArray) {
  val n = array.size
  if (n <= 1) return
  makeHeap(array, 0, n)
  sortHeap(array, 0, n)
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println(array.joinToString(", ", "[", "]"))
}
