fun multiSwap(arr: IntArray, pos: Int, to: Int) {
  if (to - pos > 0) {
    for (i in pos until to) {
      val tmp = arr[i]
      arr[i] = arr[i + 1]
      arr[i + 1] = tmp
    }
  } else {
    for (i in pos downTo to + 1) {
      val tmp = arr[i]
      arr[i] = arr[i - 1]
      arr[i - 1] = tmp
    }
  }
}

fun weaveInsert(arr: IntArray, start: Int, end: Int) {
  for (j in start until end) {
    var pos = j
    while (pos > start && arr[pos] <= arr[pos - 1]) {
      val tmp = arr[pos]
      arr[pos] = arr[pos - 1]
      arr[pos - 1] = tmp
      pos--
    }
  }
}

fun weaveMerge(arr: IntArray, min: Int, max: Int, mid: Int) {
  val target = mid - min
  for (i in 1..target) {
    multiSwap(arr, mid + i, min + (i * 2) - 1)
  }
  weaveInsert(arr, min, max + 1)
}

fun weaveMergeSort(arr: IntArray, min: Int, max: Int) {
  if (max - min == 0) {
    return
  } else if (max - min == 1) {
    if (arr[min] > arr[max]) {
      val tmp = arr[min]
      arr[min] = arr[max]
      arr[max] = tmp
    }
  } else {
    val mid = (min + max) / 2
    weaveMergeSort(arr, min, mid)
    weaveMergeSort(arr, mid + 1, max)
    weaveMerge(arr, min, max, mid)
  }
}

fun sort(arr: IntArray) {
  if (arr.size > 1) {
    weaveMergeSort(arr, 0, arr.size - 1)
  }
}

fun main() {
  val array = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
