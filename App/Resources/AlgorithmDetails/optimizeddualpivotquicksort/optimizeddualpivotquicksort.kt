fun swap(a: Array<Int>, i: Int, j: Int) {
  val t = a[i]; a[i] = a[j]; a[j] = t
}

fun insertionSort(a: Array<Int>, start: Int, end: Int) {
  for (i in start + 1 until end) {
    var j = i
    while (j > start && a[j] < a[j - 1]) { swap(a, j - 1, j); j-- }
  }
}

fun optimizedDualPivotQuickSort(a: Array<Int>, left: Int, right: Int, initialDivisor: Int) {
  val length = right - left
  if (length < 27) { insertionSort(a, left, right + 1); return }
  var divisor = initialDivisor
  val third = length / divisor
  var med1 = left + third
  var med2 = right - third
  if (med1 <= left) med1 = left + 1
  if (med2 >= right) med2 = right - 1
  if (a[med1] < a[med2]) { swap(a, med1, left); swap(a, med2, right) }
  else { swap(a, med1, right); swap(a, med2, left) }
  val pivot1 = a[left]
  val pivot2 = a[right]
  var less = left + 1
  var great = right - 1
  var k = less
  while (k <= great) {
    if (a[k] < pivot1) { swap(a, k, less); less++ }
    else if (a[k] > pivot2) {
      while (k < great && a[great] > pivot2) great--
      swap(a, k, great); great--
      if (a[k] < pivot1) { swap(a, k, less); less++ }
    }
    k++
  }
  val dist = great - less
  if (dist < 13) divisor++
  swap(a, less - 1, left); swap(a, great + 1, right)
  optimizedDualPivotQuickSort(a, left, less - 2, divisor)
  optimizedDualPivotQuickSort(a, great + 2, right, divisor)
  if (dist > length - 13 && pivot1 != pivot2) {
    k = less
    while (k <= great) {
      if (a[k] == pivot1) { swap(a, k, less); less++ }
      else if (a[k] == pivot2) {
        swap(a, k, great); great--
        if (a[k] == pivot1) { swap(a, k, less); less++ }
      }
      k++
    }
  }
  if (pivot1 < pivot2) optimizedDualPivotQuickSort(a, less, great, divisor)
}

fun sort(arr: Array<Int>) {
  optimizedDualPivotQuickSort(arr, 0, arr.size - 1, 3)
}

fun main() {
  var array =
    arrayOf<Int>(
      55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
      21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
    )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
