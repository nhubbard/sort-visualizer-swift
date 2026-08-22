fun stablePartition(arr: Array<Int>, start: Int, end: Int): Int {
  val pivotValue = arr[start]
  val leftList: MutableList<Int> = mutableListOf()
  val rightList: MutableList<Int> = mutableListOf()

  for (i in start + 1..end) {
    if (arr[i] < pivotValue) {
      leftList.add(arr[i])
    } else {
      rightList.add(arr[i])
    }
  }

  var writeIndex = start
  for (v in leftList) {
    arr[writeIndex++] = v
  }
  val pivotIndex = writeIndex
  arr[writeIndex++] = pivotValue
  for (v in rightList) {
    arr[writeIndex++] = v
  }
  return pivotIndex
}

fun stableQuickSort(arr: Array<Int>, start: Int, end: Int) {
  if (start < end) {
    val p = stablePartition(arr, start, end)
    stableQuickSort(arr, start, p - 1)
    stableQuickSort(arr, p + 1, end)
  }
}

fun sort(arr: Array<Int>) {
  stableQuickSort(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
