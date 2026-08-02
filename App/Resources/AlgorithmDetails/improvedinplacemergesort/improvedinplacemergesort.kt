fun push(arr: Array<Int>, p: Int, a: Int, b: Int) {
  if (a == b) {
    return
  }
  val temp = arr[p]
  arr[p] = arr[a]
  for (i in a + 1 until b) {
    arr[i - 1] = arr[i]
  }
  arr[b - 1] = temp
}

fun merge(arr: Array<Int>, a: Int, m: Int, b: Int) {
  var i = a
  var j = m
  while (i < m && j < b) {
    if (arr[i] > arr[j]) {
      j++
    } else {
      push(arr, i, m, j)
      i++
    }
  }
  while (i < m) {
    push(arr, i, m, b)
    i++
  }
}

fun mergeSort(arr: Array<Int>, a: Int, b: Int) {
  val m = a + (b - a) / 2
  if (b - a > 2) {
    if (b - a > 3) {
      mergeSort(arr, a, m)
    }
    mergeSort(arr, m, b)
  }
  merge(arr, a, m, b)
}

fun sort(arr: Array<Int>) {
  mergeSort(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}