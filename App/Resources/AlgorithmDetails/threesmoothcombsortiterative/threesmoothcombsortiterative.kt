import kotlin.math.ln
import kotlin.math.pow

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) {
    return
  }
  val pow2 = (ln((n - 1).toDouble()) / ln(2.0)).toInt()
  for (k in pow2 downTo 0) {
    val pow3 = ((ln(n.toDouble()) - k * ln(2.0)) / ln(3.0)).toInt()
    for (j in pow3 downTo 0) {
      val gap = (2.0.pow(k) * 3.0.pow(j)).toInt()
      var i = 0
      while (i + gap < n) {
        if (arr[i] > arr[i + gap]) {
          val t = arr[i]
          arr[i] = arr[i + gap]
          arr[i + gap] = t
        }
        i++
      }
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
