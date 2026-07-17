fun intPow(base: Int, exponent: Int): Int {
  var result = 1
  for (i in 0 until exponent) {
    result *= base
  }
  return result
}

fun getDigit(value: Int, power: Int, radix: Int): Int {
  return (value / intPow(radix, power)) % radix
}

fun radixMSD(array: IntArray, low: Int, high: Int, radix: Int, power: Int) {
  if (low >= high || power < 0) {
    return
  }

  val buckets = Array(radix) { mutableListOf<Int>() }
  for (i in low until high) {
    buckets[getDigit(array[i], power, radix)].add(array[i])
  }

  var index = low
  for (bucket in buckets) {
    for (value in bucket) {
      array[index++] = value
    }
  }

  var start = low
  for (bucket in buckets) {
    radixMSD(array, start, start + bucket.size, radix, power - 1)
    start += bucket.size
  }
}

fun sort(arr: IntArray) {
  if (arr.size <= 1) {
    return
  }
  val radix = 4
  var maxValue = arr[0]
  for (value in arr) {
    if (value > maxValue) {
      maxValue = value
    }
  }
  var highestPower = 0
  var probe = radix
  while (probe <= maxValue) {
    highestPower++
    probe *= radix
  }
  radixMSD(arr, 0, arr.size, radix, highestPower)
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[" + array.joinToString(", ") + "]")
}
