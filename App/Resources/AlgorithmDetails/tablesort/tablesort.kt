fun stableComp(arr: Array<Int>, table: Array<Int>, a: Int, b: Int): Boolean {
  val ta = table[a]
  val tb = table[b]
  if (arr[ta] > arr[tb]) return true
  if (arr[ta] == arr[tb]) return table[a] > table[b]
  return false
}

fun medianOfThree(arr: Array<Int>, table: Array<Int>, a: Int, b: Int) {
  val m = a + (b - 1 - a) / 2
  if (stableComp(arr, table, a, m)) {
    table[a] = table[m].also { table[m] = table[a] }
  }
  if (stableComp(arr, table, m, b - 1)) {
    table[m] = table[b - 1].also { table[b - 1] = table[m] }
    if (stableComp(arr, table, a, m)) return
  }
  table[a] = table[m].also { table[m] = table[a] }
}

fun partition(arr: Array<Int>, table: Array<Int>, a: Int, b: Int, p: Int): Int {
  var i = a - 1
  var j = b
  while (true) {
    do {
      i++
    } while (i < j && !stableComp(arr, table, i, p))
    do {
      j--
    } while (j >= i && stableComp(arr, table, j, p))
    if (i < j) {
      table[i] = table[j].also { table[j] = table[i] }
    } else {
      return j
    }
  }
}

fun quickSort(arr: Array<Int>, table: Array<Int>, a: Int, b: Int) {
  if (b - a < 3) {
    if (b - a == 2 && stableComp(arr, table, a, a + 1)) {
      table[a] = table[a + 1].also { table[a + 1] = table[a] }
    }
    return
  }
  medianOfThree(arr, table, a, b)
  val p = partition(arr, table, a + 1, b, a)
  table[a] = table[p].also { table[p] = table[a] }
  quickSort(arr, table, a, p)
  quickSort(arr, table, p + 1, b)
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  val table = Array(n) { it }
  quickSort(arr, table, 0, n)
  for (i in 0 until n) {
    if (table[i] != i) {
      val t = arr[i]
      var j = i
      var next = table[i]
      do {
        arr[j] = arr[next]
        table[j] = j
        j = next
        next = table[next]
      } while (next != i)
      arr[j] = t
      table[j] = j
    }
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
