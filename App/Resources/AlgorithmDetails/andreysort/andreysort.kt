fun swap(arr: Array<Int>, i: Int, j: Int) {
  val t = arr[i]
  arr[i] = arr[j]
  arr[j] = t
}

// Base case below length 12: repeatedly swap the minimum of the remaining
// range to the front.
fun selectionSort(arr: Array<Int>, aIn: Int, bIn: Int) {
  var a = aIn
  var b = bIn
  while (b > 1) {
    var k = 0
    for (i in 1 until b) {
      if (arr[a + k] > arr[a + i]) {
        k = i
      }
    }
    swap(arr, a, a + k)
    a++
    b--
  }
}

// Forward block-swap of l elements.
fun aswap(arr: Array<Int>, arr1In: Int, arr2In: Int, lIn: Int) {
  var arr1 = arr1In
  var arr2 = arr2In
  var l = lIn
  while (l > 0) {
    swap(arr, arr1, arr2)
    arr1++
    arr2++
    l--
  }
}

// Merges the two runs ending at arr1/arr2 (lengths l1/l2), working backward
// from their high ends into the trailing buffer that starts right after
// arr2. Returns the count of unplaced left-run elements if the right run
// ran out first (0 otherwise).
fun backmerge(arr: Array<Int>, arr1In: Int, l1In: Int, arr2In: Int, l2In: Int): Int {
  var arr1 = arr1In
  var l1 = l1In
  var arr2 = arr2In
  var l2 = l2In
  var arr0 = arr2 + l1
  while (true) {
    if (arr[arr1] > arr[arr2]) {
      swap(arr, arr1, arr0)
      arr1--
      arr0--
      l1--
      if (l1 == 0) {
        return 0
      }
    } else {
      swap(arr, arr2, arr0)
      arr2--
      arr0--
      l2--
      if (l2 == 0) {
        break
      }
    }
  }
  val res = l1
  do {
    swap(arr, arr1, arr0)
    arr1--
    arr0--
    l1--
  } while (l1 != 0)
  return res
}

// Merges arr[a..a+l) (as l/r blocks of width r) using the buffer
// arr[a+l..a+l+r): selection-sorts the block leaders, then backmerges each
// selected block into place.
fun rmerge(arr: Array<Int>, a: Int, l: Int, r: Int) {
  var i = 0
  while (i < l) {
    var q = i
    var j = i + r
    while (j < l) {
      if (arr[a + q] > arr[a + j]) {
        q = j
      }
      j += r
    }
    if (q != i) {
      aswap(arr, a + i, a + q, r)
    }
    if (i != 0) {
      aswap(arr, a + l, a + i, r)
      backmerge(arr, a + (l + r - 1), r, a + (i - 1), r)
    }
    i += r
  }
}

// Computes the block size: roughly sqrt(len), rounded up to a power of two.
fun rbnd(lenIn: Int): Int {
  var len = lenIn / 2
  var k = 0
  var i = 1
  while (i < len) {
    k++
    i *= 2
  }
  len /= k
  k = 1
  while (k <= len) {
    k *= 2
  }
  return k
}

fun msort(arr: Array<Int>, a: Int, len: Int) {
  if (len < 12) {
    selectionSort(arr, a, len)
    return
  }

  val r = rbnd(len)
  val lr = (len / r - 1) * r

  var p = 2
  while (p <= lr) {
    if (arr[a + (p - 2)] > arr[a + (p - 1)]) {
      swap(arr, a + (p - 2), a + (p - 1))
    }
    if ((p and 2) != 0) {
      p += 2
      continue
    }

    aswap(arr, a + (p - 2), a + p, 2)

    val m = len - p
    var q = 2
    while (true) {
      val q0 = 2 * q
      if (q0 > m || (p and q0) != 0) {
        break
      }
      backmerge(arr, a + (p - q - 1), q, a + (p + q - 1), q)
      q = q0
    }
    backmerge(arr, a + (p + q - 1), q, a + (p - q - 1), q)
    val q1 = q
    q *= 2

    while ((q and p) == 0) {
      q *= 2
      rmerge(arr, a + (p - q), q, q1)
    }

    p += 2
  }

  var q1 = 0
  var q = r
  while (q < lr) {
    if ((lr and q) != 0) {
      q1 += q
      if (q1 != q) {
        rmerge(arr, a + (lr - q1), q1, r)
      }
    }
    q *= 2
  }

  val s0 = len - lr
  msort(arr, a + lr, s0)
  aswap(arr, a, a + lr, s0)
  val s = s0 + backmerge(arr, a + (s0 - 1), s0, a + (lr - 1), lr - s0)
  msort(arr, a, s)
}

fun sort(arr: Array<Int>) {
  msort(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
