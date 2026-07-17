fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) {
    return
  }

  // Find the true maximum value in the array.
  var maximum = n - 1
  var next = arr[maximum]
  for (i in maximum - 1 downTo 0) {
    if (arr[i] > next) {
      next = arr[i]
    }
  }
  // Skip past any elements already sitting at the tail with that value.
  while (maximum > 0 && arr[maximum] == next) {
    maximum--
  }

  while (maximum > 0) {
    // This round's target is the max found by the previous pass.
    val target = next
    next = arr[maximum]

    // Sweep once, moving every occurrence of `target` into the shrinking tail
    // while tracking the next-highest value among what's left behind.
    for (j in maximum - 1 downTo 0) {
      if (arr[j] == target) {
        val temp = arr[j]
        arr[j] = arr[maximum]
        arr[maximum] = temp
        maximum--
      } else if (arr[j] > next) {
        next = arr[j]
      }
    }

    while (maximum > 0 && arr[maximum] == next) {
      maximum--
    }
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
