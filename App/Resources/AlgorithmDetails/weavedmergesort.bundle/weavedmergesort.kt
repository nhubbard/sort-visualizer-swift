fun merge(arr: IntArray, tmp: IntArray, length: Int, residue: Int, modulus: Int) {
  if (residue + modulus >= length) {
    return
  }
  var low = residue
  var high = residue + modulus
  val dmodulus = modulus shl 1

  merge(arr, tmp, length, low, dmodulus)
  merge(arr, tmp, length, high, dmodulus)

  var nxt = residue
  while (low < length && high < length) {
    if (arr[low] > arr[high] || (arr[low] == arr[high] && low > high)) {
      tmp[nxt] = arr[high]
      high += dmodulus
    } else {
      tmp[nxt] = arr[low]
      low += dmodulus
    }
    nxt += modulus
  }
  if (low >= length) {
    while (high < length) {
      tmp[nxt] = arr[high]
      nxt += modulus
      high += dmodulus
    }
  } else {
    while (low < length) {
      tmp[nxt] = arr[low]
      nxt += modulus
      low += dmodulus
    }
  }
  var i = residue
  while (i < length) {
    arr[i] = tmp[i]
    i += modulus
  }
}

fun sort(arr: IntArray) {
  val tmp = IntArray(arr.size)
  merge(arr, tmp, arr.size, 0, 1)
}

fun main() {
  val array = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
