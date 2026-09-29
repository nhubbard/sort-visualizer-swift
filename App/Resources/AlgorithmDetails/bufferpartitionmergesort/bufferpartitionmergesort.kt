import kotlin.math.min

fun sort(arr: Array<Int>) {
  val run = 8
  for (start in arr.indices step run) {
    val end = min(start + run, arr.size)
    for (i in start + 1 until end) {
      val value = arr[i]
      var j = i
      while (j > start && arr[j - 1] > value) {
        arr[j] = arr[j - 1]
        j--
      }
      arr[j] = value
    }
  }

  val scratch = arr.copyOf()
  var width = run
  while (width < arr.size) {
    for (start in arr.indices step 2 * width) {
      val middle = min(start + width, arr.size)
      val end = min(start + 2 * width, arr.size)
      var left = start
      var right = middle
      for (output in start until end) {
        if (left < middle && (right >= end || arr[left] < arr[right])) {
          scratch[output] = arr[left++]
        } else {
          scratch[output] = arr[right++]
        }
      }
    }
    scratch.copyInto(arr)
    width *= 2
  }
}

fun main() {
  val array = arrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
