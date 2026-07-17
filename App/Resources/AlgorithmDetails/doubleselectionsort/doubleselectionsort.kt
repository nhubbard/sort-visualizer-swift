fun doubleSelectionSort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) {
    return
  }

  var left = 0
  var right = n - 1
  var smallest = 0
  var biggest = 0

  while (left <= right) {
    for (i in left..right) {
      if (arr[i] > arr[biggest]) {
        biggest = i
      }
      if (arr[i] < arr[smallest]) {
        smallest = i
      }
    }

    if (biggest == left) {
      biggest = smallest
    }

    arr[left] = arr[smallest].also { arr[smallest] = arr[left] }
    arr[right] = arr[biggest].also { arr[biggest] = arr[right] }

    left++
    right--
    smallest = left
    biggest = right
  }
}

fun sort(arr: Array<Int>) {
  doubleSelectionSort(arr)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
