fun insertionSort(arr: Array<Int>, start: Int, end: Int) {
  for (i in start + 1 until end) {
    val key = arr[i]
    var j = i - 1
    while (j >= start && arr[j] > key) {
      arr[j + 1] = arr[j]
      j--
    }
    arr[j + 1] = key
  }
}

fun shatterPartition(arr: Array<Int>, start: Int, length: Int, num: Int): IntArray {
  var minV = arr[start]
  var maxV = arr[start]
  for (i in 1 until length) {
    if (arr[start + i] < minV) minV = arr[start + i]
    if (arr[start + i] > maxV) maxV = arr[start + i]
  }
  val valueRange = maxV - minV + 1
  val shatters = (length + num - 1) / num

  val buckets = Array(shatters) { mutableListOf<Int>() }
  for (i in 0 until length) {
    val v = arr[start + i]
    var idx = (v - minV) * shatters / valueRange
    if (idx > shatters - 1) idx = shatters - 1
    buckets[idx].add(v)
  }

  val offsets = IntArray(shatters + 1)
  for (i in 0 until shatters) offsets[i + 1] = offsets[i] + buckets[i].size

  var pos = start
  for (bucket in buckets) {
    for (v in bucket) {
      arr[pos] = v
      pos++
    }
  }
  return offsets
}

fun floorLog2(n: Int): Int {
  var log = 0
  var m = n
  while (m > 1) {
    m = m shr 1
    log++
  }
  return log
}

fun simpleShatterSort(arr: Array<Int>, length: Int, num: Int, rate: Int) {
  var i = num
  while (i > 1) {
    shatterPartition(arr, 0, length, i)
    i /= rate
  }
  val offsets = shatterPartition(arr, 0, length, 1)
  for (k in 0 until offsets.size - 1) {
    if (offsets[k + 1] - offsets[k] > 1) insertionSort(arr, offsets[k], offsets[k + 1])
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  val rate = maxOf(2, floorLog2(n) / 2)
  simpleShatterSort(arr, n, 4, rate)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
