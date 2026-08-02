fun forward(arr: Array<Int>, leftStart: Int, rightStart: Int) {
  var left = leftStart
  var right = rightStart
  while (left < right) {
    var index = right
    while (left < index) {
      if (arr[left] > arr[index]) {
        arr[left] = arr[index].also { arr[index] = arr[left] }
      }
      left++
      index--
    }
    left = 0
    right--
  }
}

fun backward(arr: Array<Int>, leftStart: Int, rightStart: Int) {
  var left = leftStart
  var right = rightStart
  val length = right
  while (left < right) {
    var index = left
    while (index < right) {
      if (arr[index] > arr[right]) {
        arr[index] = arr[right].also { arr[right] = arr[index] }
      }
      index++
      right--
    }
    left++
    right = length
  }
}

fun exchange(arr: Array<Int>, length: Int) {
  var left = 0
  var right = length - 1
  while (left < right) {
    if (arr[left] > arr[right]) {
      arr[left] = arr[right].also { arr[right] = arr[left] }
    }
    left++
    right--
  }

  forward(arr, 0, length - 2)
  backward(arr, 1, length - 1)
}

fun sort(arr: Array<Int>) {
  exchange(arr, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
