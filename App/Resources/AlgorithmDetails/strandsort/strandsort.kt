fun mergeTo(arr: Array<Int>, subList: Array<Int>, a0: Int, m0: Int, b: Int) {
  var a = a0
  var m = m0
  var i = 0
  val s = m - a
  while (i < s && m < b) {
    if (subList[i] < arr[m]) {
      arr[a] = subList[i]
      a++
      i++
    } else {
      arr[a] = arr[m]
      a++
      m++
    }
  }
  while (i < s) {
    arr[a] = subList[i]
    a++
    i++
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return

  val subList = Array(n) { 0 }

  var j = n
  var k = j
  while (j > 0) {
    subList[0] = arr[0]
    k--

    var i = 0
    var p = 0
    var m = 1
    while (m < j) {
      if (arr[m] >= subList[i]) {
        i++
        subList[i] = arr[m]
        k--
      } else {
        arr[p] = arr[m]
        p++
      }
      m++
    }

    mergeTo(arr, subList, k, j, n)
    j = k
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
