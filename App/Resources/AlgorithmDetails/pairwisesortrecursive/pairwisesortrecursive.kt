fun sort(arr: Array<Int>) {
  fun compSwap(a: Int, b: Int) {
    if (arr[a] > arr[b]) {
      val temp = arr[a]
      arr[a] = arr[b]
      arr[b] = temp
    }
  }

  fun pairwiseRecursive(start: Int, end: Int, gap: Int) {
    if (start == end - gap) return
    var b = start + gap
    while (b < end) {
      compSwap(b - gap, b)
      b += 2 * gap
    }

    if (((end - start) / gap) % 2 == 0) {
      pairwiseRecursive(start, end, gap * 2)
      pairwiseRecursive(start + gap, end + gap, gap * 2)
    } else {
      pairwiseRecursive(start, end + gap, gap * 2)
      pairwiseRecursive(start + gap, end, gap * 2)
    }

    var a = 1
    while (a < (end - start) / gap) {
      a = (a * 2) + 1
    }

    b = start + gap
    while (b + gap < end) {
      var c = a
      while (c > 1) {
        c /= 2
        if (b + (c * gap) < end) {
          compSwap(b, b + (c * gap))
        }
      }
      b += 2 * gap
    }
  }

  pairwiseRecursive(0, arr.size, 1)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
