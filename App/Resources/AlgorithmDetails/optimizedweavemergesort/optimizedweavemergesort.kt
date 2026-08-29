fun insertTo(arr: Array<Int>, aInit: Int, b: Int) {
  var a = aInit
  val temp = arr[a]
  while (a > b) {
    a--
    arr[a + 1] = arr[a]
  }
  arr[b] = temp
}

fun multiSwap(arr: Array<Int>, a: Int, b: Int, len: Int) {
  for (i in 0 until len) {
    arr[a + i] = arr[b + i].also { arr[b + i] = arr[a + i] }
  }
}

fun rotate(arr: Array<Int>, aInit: Int, mInit: Int, bInit: Int) {
  var a = aInit
  var m = mInit
  var b = bInit
  var l = m - a
  var r = b - m
  while (l > 0 && r > 0) {
    if (r < l) {
      multiSwap(arr, m - r, m, r)
      b -= r
      m -= r
      l -= r
    } else {
      multiSwap(arr, a, m, l)
      a += l
      m += l
      r -= l
    }
  }
}

fun bitReversal(arr: Array<Int>, a: Int, b: Int) {
  val len = b - a
  var m = 0
  val d1 = len shr 1
  val d2 = d1 + (d1 shr 1)
  var i = 1
  while (i < len - 1) {
    var j = d1
    var k = i
    var nn = d2
    while (k and 1 == 0) {
      j -= nn
      k = k shr 1
      nn = nn shr 1
    }
    m += j
    if (m > i) {
      arr[a + i] = arr[a + m].also { arr[a + m] = arr[a + i] }
    }
    i++
  }
}

fun weaveInsert(arr: Array<Int>, a: Int, b: Int, rightInit: Boolean) {
  var right = rightInit
  var i = a
  var j = a + 1
  while (j < b) {
    if (right) {
      while (i < j && arr[i] <= arr[j]) i++
    } else {
      while (i < j && arr[i] < arr[j]) i++
    }
    if (i == j) {
      right = !right
      j++
    } else {
      insertTo(arr, j, i)
      i++
      j += 2
    }
  }
}

fun weaveMerge(arr: Array<Int>, a: Int, mInit: Int, b: Int) {
  if (b - a < 2) return
  var a1 = a
  var b1 = b
  var right = true
  if ((b - a) % 2 == 1) {
    if (mInit - a < b - mInit) {
      a1 -= 1
      right = false
    } else {
      b1 += 1
    }
  }
  var e = b1
  while (e - a1 > 2) {
    var m = (a1 + e) / 2
    var p = 1
    while (p * 2 <= m - a1) p *= 2
    rotate(arr, m - p, m, e - p)
    m = e - p
    val f = m - p
    bitReversal(arr, f, m)
    bitReversal(arr, m, e)
    bitReversal(arr, f, e)
    e = f
  }
  weaveInsert(arr, a, b, right)
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) return
  var d = 1
  while (d < n) d = d shl 1
  while (d > 1) {
    var i = 0
    var dec = 0
    while (i < n) {
      var j = i
      dec += n
      while (dec >= d) {
        dec -= d
        j++
      }
      var k = j
      dec += n
      while (dec >= d) {
        dec -= d
        k++
      }
      weaveMerge(arr, i, j, k)
      i = k
    }
    d /= 2
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
