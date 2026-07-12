fun sort(array: IntArray) {
  val currentLen = array.size
  for (i in 0 until currentLen) {
    var shortest = i

    var j = i
    while (j < currentLen) {
      var isShortest = true
      var k = j + 1
      while (k < currentLen) {
        if (array[j] > array[k]) {
          isShortest = false
          break
        }
        k++
      }
      if (isShortest) {
        shortest = j
        break
      }
      j++
    }

    val temp = array[i]
    array[i] = array[shortest]
    array[shortest] = temp
  }
}

fun main() {
  val array = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
