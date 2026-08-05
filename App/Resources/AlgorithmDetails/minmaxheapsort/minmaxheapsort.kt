fun bitLength(valueIn: Int): Int {
  var value = valueIn
  var length = 0
  while (value > 0) {
    value = value shr 1
    length++
  }
  return length
}

fun isMinLevel(index: Int): Boolean = bitLength(index + 1) % 2 == 1

fun betterThan(a: Int, b: Int, minLevel: Boolean): Boolean = if (minLevel) a < b else a > b

fun downheap(arr: IntArray, start: Int, size: Int) {
  var i = start
  while (true) {
    val minLevel = isMinLevel(i)
    val left = 2 * i + 1
    val right = 2 * i + 2
    if (left >= size) return
    var winner = left
    if (right < size && betterThan(arr[right], arr[winner], minLevel)) winner = right
    val base = 4 * i + 3
    for (offset in 0 until 4) {
      val gc = base + offset
      if (gc < size && betterThan(arr[gc], arr[winner], minLevel)) winner = gc
    }
    val isGrandchild = winner >= base
    val extreme = betterThan(arr[winner], arr[i], minLevel)
    if (!isGrandchild) {
      if (extreme) {
        val temp = arr[i]
        arr[i] = arr[winner]
        arr[winner] = temp
      }
      return
    }
    if (extreme) {
      val temp = arr[i]
      arr[i] = arr[winner]
      arr[winner] = temp
    } else {
      return
    }
    val parent = (winner - 1) / 2
    if (minLevel) {
      if (arr[winner] > arr[parent]) {
        val temp = arr[parent]
        arr[parent] = arr[winner]
        arr[winner] = temp
      }
    } else {
      if (arr[winner] < arr[parent]) {
        val temp = arr[parent]
        arr[parent] = arr[winner]
        arr[winner] = temp
      }
    }
    i = winner
  }
}

fun heapify(arr: IntArray, length: Int) {
  for (i in (length - 1) / 2 downTo 0) {
    downheap(arr, i, length)
  }
}

fun storeMax(arr: IntArray, heapSize: Int): Int {
  if (heapSize <= 1) return heapSize
  var imax = 1
  if (heapSize > 2 && arr[2] > arr[1]) imax = 2
  val last = heapSize - 1
  val temp = arr[imax]
  arr[imax] = arr[last]
  arr[last] = temp
  val newSize = last
  if (imax < newSize) downheap(arr, imax, newSize)
  return newSize
}

fun sort(arr: IntArray) {
  val n = arr.size
  if (n <= 1) return
  heapify(arr, n)
  var heapSize = n
  for (i in 0 until n - 1) {
    heapSize = storeMax(arr, heapSize)
  }
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println(array.joinToString(", ", "[", "]"))
}
