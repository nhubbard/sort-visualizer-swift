fun siftDown(arr: Array<Int>, root: Int, size: Int) {
  var index = root
  while (2 * index + 1 < size) {
    var child = 2 * index + 1
    if (child + 1 < size && arr[child + 1] > arr[child]) child++
    index = child
  }
  val rootValue = arr[root]
  while (rootValue > arr[index]) {
    index = (index - 1) / 2
  }
  while (index != root) {
    val temp = arr[root]
    arr[root] = arr[index]
    arr[index] = temp
    index = (index - 1) / 2
  }
}

fun heapify(arr: Array<Int>, length: Int) {
  for (i in (length - 1) / 2 downTo 0) {
    siftDown(arr, i, length)
  }
}

fun findNext(arr: Array<Int>, size: Int) {
  var hole = 0
  var left = 1
  var right = 2
  while (right < size && !(arr[left] == -1 && arr[right] == -1)) {
    if (arr[left] == -1) {
      val temp = arr[hole]
      arr[hole] = arr[right]
      arr[right] = temp
      hole = right
    } else if (arr[right] == -1) {
      val temp = arr[hole]
      arr[hole] = arr[left]
      arr[left] = temp
      hole = left
    } else if (arr[right] > arr[left]) {
      val temp = arr[hole]
      arr[hole] = arr[right]
      arr[right] = temp
      hole = right
    } else {
      val temp = arr[hole]
      arr[hole] = arr[left]
      arr[left] = temp
      hole = left
    }
    left = 2 * hole + 1
    right = left + 1
  }
  if (left < size && arr[left] != -1) {
    val temp = arr[hole]
    arr[hole] = arr[left]
    arr[left] = temp
  }
}

fun sort(arr: Array<Int>): Array<Int> {
  val n = arr.size
  val output = Array(n) { 0 }
  if (n <= 1) {
    if (n == 1) output[0] = arr[0]
    return output
  }
  heapify(arr, n)
  for (i in n - 1 downTo 0) {
    output[i] = arr[0]
    arr[0] = -1
    findNext(arr, n)
  }
  return output
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  val output = sort(array)
  println("[%s]".format(output.joinToString(", ")))
}
