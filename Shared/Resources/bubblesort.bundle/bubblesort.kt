fun bubbleSort(arr: Array<Int>, n: Int) {
  for (c in 0..(n - 1)) {
    for (d in 0..(n - c - 1)) {
      if (arr[d] > arr[d + 1]) {
        var temp = arr[d]
        arr[d] = arr[d + 1]
        arr[d + 1] = temp
      }
    }
  }
}

fun main() {
  var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
  bubbleSort(items, items.size - 1);
  println("[%s]".format(items.joinToString(", ")))
}