fun insertionSort(arr: Array<Int>, start: Int, end: Int) {
  for (i in start + 1 until end) {
    var pos = i
    while (pos > start && arr[pos - 1] > arr[pos]) {
      val temp = arr[pos - 1]
      arr[pos - 1] = arr[pos]
      arr[pos] = temp
      pos--
    }
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

fun shatterSort(arr: Array<Int>, length: Int, num: Int) {
  val offsets = shatterPartition(arr, 0, length, num)
  for (i in 0 until offsets.size - 1) {
    if (offsets[i + 1] - offsets[i] > 1) insertionSort(arr, offsets[i], offsets[i + 1])
  }
}

fun sort(arr: Array<Int>) {
  if (arr.size < 2) return
  shatterSort(arr, arr.size, 4)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
