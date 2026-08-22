fun stableComp(arr: Array<Int>, key: Array<Int>, a: Int, b: Int): Boolean {
  if (arr[a] > arr[b]) return true
  if (arr[a] == arr[b]) return key[a] > key[b]
  return false
}

fun stableSwap(arr: Array<Int>, key: Array<Int>, a: Int, b: Int) {
  val t = arr[a]
  arr[a] = arr[b]
  arr[b] = t
  val tk = key[a]
  key[a] = key[b]
  key[b] = tk
}

fun medianOfThree(arr: Array<Int>, key: Array<Int>, a: Int, b: Int) {
  val m = a + (b - 1 - a) / 2
  if (stableComp(arr, key, a, m)) stableSwap(arr, key, a, m)
  if (stableComp(arr, key, m, b - 1)) {
    stableSwap(arr, key, m, b - 1)
    if (stableComp(arr, key, a, m)) return
  }
  stableSwap(arr, key, a, m)
}

fun partition(arr: Array<Int>, key: Array<Int>, a: Int, b: Int, p: Int): Int {
  var i = a - 1
  var j = b
  while (true) {
    do {
      i++
    } while (i < j && !stableComp(arr, key, i, p))
    do {
      j--
    } while (j >= i && stableComp(arr, key, j, p))
    if (i < j) {
      stableSwap(arr, key, i, j)
    } else {
      return j
    }
  }
}

fun quickSort(arr: Array<Int>, key: Array<Int>, a: Int, b: Int) {
  if (b - a < 3) {
    if (b - a == 2 && stableComp(arr, key, a, a + 1)) stableSwap(arr, key, a, a + 1)
    return
  }
  medianOfThree(arr, key, a, b)
  val p = partition(arr, key, a + 1, b, a)
  stableSwap(arr, key, a, p)
  quickSort(arr, key, a, p)
  quickSort(arr, key, p + 1, b)
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  val key = Array(n) { it }
  quickSort(arr, key, 0, n)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}