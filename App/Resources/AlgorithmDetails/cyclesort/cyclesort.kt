fun cycleSort(arr: Array<Int>) {
  val n = arr.size
  for (cycleStart in 0..(n - 2)) {
    var item = arr[cycleStart]
    var pos = cycleStart
    for (i in (cycleStart + 1)..(n - 1)) {
      if (arr[i] < item) pos++
    }
    if (pos == cycleStart) continue

    while (item == arr[pos]) pos++
    arr[pos] = item.also { item = arr[pos] }

    while (pos != cycleStart) {
      pos = cycleStart
      for (i in (cycleStart + 1)..(n - 1)) {
        if (arr[i] < item) pos++
      }
      while (item == arr[pos]) pos++
      arr[pos] = item.also { item = arr[pos] }
    }
  }
}

fun sort(arr: Array<Int>) {
  cycleSort(arr)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
