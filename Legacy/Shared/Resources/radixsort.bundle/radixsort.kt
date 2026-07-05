fun sort(arr: Array<Int>) {
  val n = arr.size
  var bucket = Array(10) { Array(10) { 0 } }
  var bucketCount = Array(10) { 0 }
  var lar: Int
  var nop = 0
  var divisor = 1
  lar = arr.maxOrNull() ?: 0
  while (lar > 0) {
    nop++
    lar /= 10
  }
  for (pass in 0 until nop) {
    for (i in 0 until 10) {
      bucketCount[i] = 0
    }
    for (i in 0 until n) {
      val r = (arr[i] / divisor) % 10
      bucket[r][bucketCount[r]] = arr[i]
      bucketCount[r] += 1
    }
    var i = 0
    for (k in 0 until 10) {
      for (j in 0 until bucketCount[k]) {
        arr[i] = bucket[k][j]
        i++
      }
    }
    divisor *= 10
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}