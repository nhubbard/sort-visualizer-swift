fun sort(arr: Array<Int>) {
  val length = arr.size
  var a = 1
  while (a < length) {
    var b = a
    var c = 0
    while (b < length) {
      if (arr[b - a] > arr[b]) {
        arr[b - a] = arr[b].also { arr[b] = arr[b - a] }
      }
      c = (c + 1) % a
      b++
      if (c == 0) b += a
    }
    a *= 2
  }

  a /= 4
  var e = 1
  while (a > 0) {
    var d = e
    while (d > 0) {
      var b = (d + 1) * a
      var c = 0
      while (b < length) {
        if (arr[b - (d * a)] > arr[b]) {
          arr[b - (d * a)] = arr[b].also { arr[b] = arr[b - (d * a)] }
        }
        c = (c + 1) % a
        b++
        if (c == 0) b += a
      }
      d /= 2
    }
    a /= 2
    e = (e * 2) + 1
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
