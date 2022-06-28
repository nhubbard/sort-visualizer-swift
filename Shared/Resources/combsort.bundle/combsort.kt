import kotlin.math.floor

fun sort(arr: Array<Int>) {
  val n = arr.size
  var sm: Int
  var shrink: Double = 1.3
  var gap = n
  var sorted = false
  while (!sorted) {
    gap = floor(gap / shrink).toInt()
    if (gap <= 1) {
      sorted = true;
      gap = 1;
    }
    for (i in 0 until (n - gap)) {
      sm = gap + i;
      if (arr[i] > arr[sm]) {
        arr[i] = arr[sm].also { arr[sm] = arr[i] }
        sorted = false
      }
    }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
