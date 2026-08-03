fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) return

  val empty = Int.MIN_VALUE
  var capacity = 0
  var slots = IntArray(0)
  // Physical `slots` index of each placed element, ascending by both position and value.
  var positions = mutableListOf<Int>()

  fun rebalance() {
    val count = positions.size
    val newCapacity = maxOf(2, count * 2)
    val newSlots = IntArray(newCapacity) { empty }
    val newPositions = mutableListOf<Int>()
    for (i in 0 until count) {
      val pos = positions[i]
      val newPos = i * 2
      newSlots[newPos] = slots[pos]
      newPositions.add(newPos)
    }
    slots = newSlots
    positions = newPositions
    capacity = newCapacity
  }

  fun insert(value: Int) {
    if (positions.size == capacity) {
      rebalance()
    }

    // Upper-bound binary search: first slot whose value is strictly greater than `value`.
    var lo = 0
    var hi = positions.size
    while (lo < hi) {
      val mid = (lo + hi) / 2
      if (slots[positions[mid]] > value) {
        hi = mid
      } else {
        lo = mid + 1
      }
    }
    val k = lo
    val targetPos = if (k == 0) 0 else positions[k - 1] + 1

    if (!(targetPos == capacity || slots[targetPos] != empty)) {
      slots[targetPos] = value
      positions.add(k, targetPos)
      return
    }

    // Either targetPos is already occupied, or targetPos == capacity (new maximum, no room
    // left of the structure's end). Search BOTH directions for the nearest gap and shift
    // whichever side is closer.
    var leftGap = targetPos - 1
    while (leftGap >= 0 && slots[leftGap] != empty) {
      leftGap--
    }
    var rightGap = targetPos
    while (rightGap < capacity && slots[rightGap] != empty) {
      rightGap++
    }
    val leftDistance = if (leftGap >= 0) targetPos - leftGap else Int.MAX_VALUE
    val rightDistance = if (rightGap < capacity) rightGap - targetPos else Int.MAX_VALUE

    if (rightDistance <= leftDistance) {
      var i = rightGap
      while (i > targetPos) {
        slots[i] = slots[i - 1]
        i--
      }
      for (idx in k until k + (rightGap - targetPos)) {
        positions[idx] = positions[idx] + 1
      }
      slots[targetPos] = value
      positions.add(k, targetPos)
    } else {
      val shiftCount = (targetPos - 1) - leftGap
      var i = leftGap
      while (i < targetPos - 1) {
        slots[i] = slots[i + 1]
        i++
      }
      for (idx in (k - shiftCount) until k) {
        positions[idx] = positions[idx] - 1
      }
      slots[targetPos - 1] = value
      positions.add(k, targetPos - 1)
    }
  }

  for (v in arr) {
    insert(v)
  }

  for (i in positions.indices) {
    arr[i] = slots[positions[i]]
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
