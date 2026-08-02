import java.util.PriorityQueue

fun sort(arr: Array<Int>) {
  val n = arr.size
  val piles = mutableListOf<MutableList<Int>>()
  val tops = mutableListOf<Int>()

  for (x in arr) {
    // binary search: leftmost pile whose top is >= x
    var lo = 0
    var hi = piles.size
    while (lo < hi) {
      val mid = (lo + hi) / 2
      if (tops[mid] >= x) {
        hi = mid
      } else {
        lo = mid + 1
      }
    }
    if (lo == piles.size) {
      piles.add(mutableListOf(x))
      tops.add(x)
    } else {
      piles[lo].add(x)
      tops[lo] = x
    }
  }

  val heap = PriorityQueue<Pair<Int, Int>>(compareBy { it.first })
  for (i in piles.indices) {
    heap.add(Pair(tops[i], i))
  }

  val result = mutableListOf<Int>()
  while (heap.isNotEmpty()) {
    val (_, pileIndex) = heap.poll()
    val value = piles[pileIndex].removeAt(piles[pileIndex].size - 1)
    result.add(value)
    val newTop = piles[pileIndex].lastOrNull()
    if (newTop != null) {
      heap.add(Pair(newTop, pileIndex))
    }
  }

  for (i in 0 until n) {
    arr[i] = result[i]
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