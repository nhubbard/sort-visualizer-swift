fun intPow(base: Int, exponent: Int): Int {
  var result = 1
  for (i in 0 until exponent) {
    result *= base
  }
  return result
}

fun getDigit(value: Int, power: Int, radix: Int): Int = (value / intPow(radix, power)) % radix

fun multiSwap(arr: Array<Int>, pos: Int, to: Int) {
  if (to > pos) {
    for (k in pos until to) {
      val temp = arr[k]
      arr[k] = arr[k + 1]
      arr[k + 1] = temp
    }
  } else if (to < pos) {
    for (k in pos downTo to + 1) {
      val temp = arr[k]
      arr[k] = arr[k - 1]
      arr[k - 1] = temp
    }
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n == 0) {
    return
  }
  val radix = 4
  var maxValue = arr[0]
  for (value in arr) {
    if (value > maxValue) {
      maxValue = value
    }
  }

  var maxPower = 0
  var probe = radix
  while (probe <= maxValue) {
    maxPower++
    probe *= radix
  }

  val vregs = IntArray(radix - 1)

  for (power in 0..maxPower) {
    for (i in vregs.indices) {
      vregs[i] = n - 1
    }

    var pos = 0
    for (step in 0 until n) {
      val digit = getDigit(arr[pos], power, radix)
      if (digit == 0) {
        pos++
      } else {
        val to = vregs[digit - 1]
        multiSwap(arr, pos, to)
        for (j in digit - 1 downTo 1) {
          vregs[j - 1]--
        }
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
