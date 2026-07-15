fun merge(arr: Array<Int>, flags: Array<Boolean>, i: Int, j: Int) {
  if (arr[i] < arr[j]) {
    flags[j] = !flags[j]
    arr[i] = arr[j].also { arr[j] = arr[i] }
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  val flags = Array(n) { false }

  for (i in (n - 1) downTo 1) {
    var j = i
    while ((j and 1) == (if (flags[j shr 1]) 1 else 0)) {
      j = j shr 1
    }
    val gparent = j shr 1
    merge(arr, flags, gparent, i)
  }

  for (i in (n - 1) downTo 2) {
    arr[0] = arr[i].also { arr[i] = arr[0] }
    var x = 1
    while (true) {
      val y = 2 * x + (if (flags[x]) 1 else 0)
      if (y >= i) {
        break
      }
      x = y
    }
    while (x > 0) {
      merge(arr, flags, 0, x)
      x = x shr 1
    }
  }
  arr[0] = arr[1].also { arr[1] = arr[0] }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
