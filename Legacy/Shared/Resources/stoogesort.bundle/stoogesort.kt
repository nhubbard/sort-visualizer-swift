fun sort(arr: Array<Int>, i: Int, j: Int) {
  if (arr[j] < arr[i]) {
    arr[i] = arr[j].also { arr[j] = arr[i] }
  }
  if (j - i > 1) {
    val t = (j - i + 1) / 3;
    sort(arr, i, j - t);
    sort(arr, i + t, j);
    sort(arr, i, j - t);
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array, 0, array.size - 1)
  println("[%s]".format(array.joinToString(", ")))
}
