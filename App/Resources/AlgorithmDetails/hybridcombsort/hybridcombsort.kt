import kotlin.math.floor
import kotlin.math.min

fun sort(arr: Array<Int>) {
  val n = arr.size
  var sm: Int
  val shrink: Double = 1.3
  var gap = n
  var sorted = false
  val threshold = min(8, n / 32)
  while (!sorted) {
    gap = floor(gap / shrink).toInt()
    if (gap <= 1) {
      sorted = true
      gap = 1
    }
    for (i in 0 until (n - gap)) {
      if (gap <= threshold) {
        insertionSort(arr)
        return
      }
      sm = gap + i
      if (arr[i] > arr[sm]) {
        arr[i] = arr[sm].also { arr[sm] = arr[i] }
        sorted = false
      }
    }
  }
}

fun insertionSort(arr: Array<Int>) {
  val n = arr.size
  for (i in 1 until n) {
    var j = i
    while (j > 0 && arr[j - 1] > arr[j]) {
      val temp = arr[j]
      arr[j] = arr[j - 1]
      arr[j - 1] = temp
      j--
    }
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
