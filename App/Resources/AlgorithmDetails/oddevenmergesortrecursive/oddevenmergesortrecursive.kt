fun oddEvenMergeCompare(arr: Array<Int>, i: Int, j: Int) {
  if (arr[i] > arr[j]) {
    arr[i] = arr[j].also { arr[j] = arr[i] }
  }
}

// lo is the starting position, m2 is the halfway point, n is the length of
// the piece being merged, and r is the distance of the elements compared.
fun oddEvenMerge(arr: Array<Int>, lo: Int, m2: Int, n: Int, r: Int) {
  val m = r * 2
  if (m < n) {
    if ((n / r) % 2 != 0) {
      oddEvenMerge(arr, lo, (m2 + 1) / 2, n + r, m) // even subsequence
      oddEvenMerge(arr, lo + r, m2 / 2, n - r, m) // odd subsequence
    } else {
      oddEvenMerge(arr, lo, (m2 + 1) / 2, n, m) // even subsequence
      oddEvenMerge(arr, lo + r, m2 / 2, n, m) // odd subsequence
    }

    if (m2 % 2 != 0) {
      var i = lo
      while (i + r < lo + n) {
        oddEvenMergeCompare(arr, i, i + r)
        i += m
      }
    } else {
      var i = lo + r
      while (i + r < lo + n) {
        oddEvenMergeCompare(arr, i, i + r)
        i += m
      }
    }
  } else {
    if (n > r) {
      oddEvenMergeCompare(arr, lo, lo + r)
    }
  }
}

fun oddEvenMergeSort(arr: Array<Int>, lo: Int, n: Int) {
  if (n > 1) {
    val m = n / 2
    oddEvenMergeSort(arr, lo, m)
    oddEvenMergeSort(arr, lo + m, n - m)
    oddEvenMerge(arr, lo, m, n, 1)
  }
}

fun sort(arr: Array<Int>) {
  oddEvenMergeSort(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
