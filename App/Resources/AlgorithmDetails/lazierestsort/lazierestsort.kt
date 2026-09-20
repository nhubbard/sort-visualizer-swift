fun sort(arr: Array<Int>) {
  val n = arr.size

  fun reverse(a: Int, end: Int) {
    var i = a
    var j = end - 1
    while (i < j) {
      val t = arr[i]
      arr[i++] = arr[j]
      arr[j--] = t
    }
  }

  fun rotate(a: Int, m: Int, b: Int) {
    reverse(a, m)
    reverse(m, b)
    reverse(a, b)
  }

  fun search(start: Int, end: Int, value: Int, upper: Boolean): Int {
    var a = start
    var b = end
    while (a < b) {
      val mid = (a + b) / 2
      if (value < arr[mid] || (!upper && value == arr[mid])) b = mid else a = mid + 1
    }
    return a
  }

  fun gallop(a: Int, b: Int, value: Int, backwards: Boolean): Int {
    var step = 1
    if (backwards) {
      while (b - step >= a && value < arr[b - step]) step *= 2
      return search(maxOf(a, b - step + 1), b - step / 2, value, true)
    }
    while (a - 1 + step < b && value > arr[a - 1 + step]) step *= 2
    return search(a + step / 2, minOf(b, a - 1 + step), value, false)
  }

  fun insertion(a: Int, b: Int) {
    for (i in a + 1 until b) {
      val value = arr[i]
      val position = search(a, i, value, true)
      for (j in i downTo position + 1) arr[j] = arr[j - 1]
      arr[position] = value
    }
  }

  fun forward(a: Int, m: Int, b: Int) {
    var i = a
    var j = m
    while (i < j && j < b) {
      if (arr[i] > arr[j]) {
        val k = gallop(j + 1, b, arr[i], false)
        rotate(i, j, k)
        i += k - j
        j = k
      } else {
        i++
      }
    }
  }

  fun backward(a: Int, m: Int, b: Int) {
    var i = m - 1
    var j = b - 1
    while (j > i && i >= a) {
      if (arr[i] > arr[j]) {
        val k = gallop(a, i, arr[j], true)
        rotate(k, i + 1, j + 1)
        j -= i + 1 - k
        i = k - 1
      } else {
        j--
      }
    }
  }

  fun merge(a: Int, m: Int, b: Int) {
    if (b - m < m - a) backward(a, m, b) else forward(a, m, b)
  }

  fun fragmented(start: Int, middle: Int, end: Int, size: Int) {
    var a = start
    var m = middle
    var i = a + (m - a) % size
    while (i < m) {
      val j = gallop(m, end, arr[i], false)
      rotate(i, m, j)
      val length = j - m
      val boundary = i
      i += length
      m += length
      merge(a, boundary, i)
      a = i
      i += size
    }
    merge(maxOf(a, i - size), i, end)
  }
  if (n <= 16) {
    insertion(0, n)
    return
  }
  var size = 1
  while (size * size * size < n) size++
  val group = size * size
  var i = n % size
  while (i <= n) {
    insertion(maxOf(0, i - size), i)
    i += size
  }
  i = n - size
  var j = n
  while (i > 0) {
    if (j - i == group) {
      j -= group
      i -= size
    }
    forward(maxOf(0, i - size), i, j)
    i -= size
  }
  i = n - group
  while (i > 0) {
    fragmented(maxOf(0, i - group), i, n, size)
    i -= group
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
    10, 2, 95, 46, 21, 74, 6, 38,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
