fun sort(arr: Array<Int>) {
  val n = arr.size
  val loops = IntArray(n)
  val indexes = IntArray(n)

  fun isValid(): Boolean {
    var total = 0
    for (i in 0 until n) {
      for (j in 0 until n) {
        if (loops[i] == loops[j]) {
          total += 1
        }
      }
    }
    for (i in 0 until n) {
      for (j in 0 until n) {
        if (i < j && arr[loops[i]] > arr[loops[j]]) {
          total += 1
        } else if (i > j && arr[loops[i]] < arr[loops[j]]) {
          total += 1
        }
      }
    }
    return total == n
  }

  while (true) {
    if (isValid()) {
      for (i in 0 until n) {
        indexes[i] = loops[i]
      }
    }
    var pos = 0
    while (pos < n) {
      if (loops[pos] < n - 1) {
        loops[pos] += 1
        break
      } else {
        loops[pos] = 0
        pos += 1
      }
    }
    if (pos == n) {
      break
    }
  }

  val original = arr.copyOf()
  for (i in 0 until n) {
    arr[i] = original[indexes[i]]
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 14)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
