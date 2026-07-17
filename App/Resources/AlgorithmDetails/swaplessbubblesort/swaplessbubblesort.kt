fun swaplessBubbleSort(arr: Array<Int>) {
  var i = arr.size
  while (i > 0) {
    var last = 0
    var pos = 0
    var comp = arr[0]
    for (j in 1 until i) {
      if (comp > arr[j]) {
        arr[j - 1] = arr[j]
        last = j
      } else {
        if (pos + 1 < j) {
          arr[j - 1] = comp
        }
        pos = j
        comp = arr[j]
      }
    }
    arr[i - 1] = comp
    i = last
  }
}

fun sort(arr: Array<Int>) {
  swaplessBubbleSort(arr)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
