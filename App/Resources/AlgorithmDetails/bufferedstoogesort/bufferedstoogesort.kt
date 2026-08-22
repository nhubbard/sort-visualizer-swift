fun bufferedStoogeSort(arr: Array<Int>, start: Int, stop: Int) {
  if (stop - start > 1) {
    if (stop - start == 2 && arr[start] > arr[stop - 1]) {
      arr[start] = arr[stop - 1].also { arr[stop - 1] = arr[start] }
    }
    if (stop - start > 2) {
      val width = stop - start
      val third = (width + 2) / 3 + start
      var twoThird = (2 * width + 2) / 3 + start
      if (twoThird - third < third) {
        twoThird--
      }
      if ((width - 2) % 3 == 0) {
        twoThird--
      }

      bufferedStoogeSort(arr, third, twoThird)
      bufferedStoogeSort(arr, twoThird, stop)

      var left = third
      var right = twoThird
      var bufferStart = start
      while (left < twoThird && right < stop) {
        if (arr[left] > arr[right]) {
          arr[bufferStart] = arr[right].also { arr[right] = arr[bufferStart] }
          right++
        } else {
          arr[bufferStart] = arr[left].also { arr[left] = arr[bufferStart] }
          left++
        }
        bufferStart++
      }
      while (right < stop) {
        arr[bufferStart] = arr[right].also { arr[right] = arr[bufferStart] }
        right++
        bufferStart++
      }

      bufferedStoogeSort(arr, twoThird, stop)

      left = twoThird - 1
      right = stop - 1
      while (right > left && left >= start) {
        if (arr[left] > arr[right]) {
          for (i in left until right) {
            arr[i] = arr[i + 1].also { arr[i + 1] = arr[i] }
          }
          left--
        }
        right--
      }
    }
  }
}

fun sort(arr: Array<Int>) {
  bufferedStoogeSort(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}