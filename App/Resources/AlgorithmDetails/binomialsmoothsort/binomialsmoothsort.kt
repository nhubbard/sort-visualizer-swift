fun sort(arr: Array<Int>) {
  val n = arr.size

  fun height(node: Int): Int {
    var count = 0
    while ((node shr count) % 2 == 1) {
      count += 1
    }
    return count
  }

  fun thrift(node: Int, parentFlag: Boolean, rootFlag: Boolean) {
    val isRoot = rootFlag && (node >= (1 shl height(node)))
    if (!isRoot && !parentFlag) {
      return
    }

    var choice = height(node) - (if (isRoot) 0 else 1)
    if (parentFlag) {
      for (child in choice - 1 downTo 0) {
        if (arr[node - (1 shl choice)] <= arr[node - (1 shl child)]) {
          choice = child
        }
      }
    }

    if (arr[node - (1 shl choice)] <= arr[node]) {
      return
    }

    val temp = arr[node]
    arr[node] = arr[node - (1 shl choice)]
    arr[node - (1 shl choice)] = temp
    val nextNode = node - (1 shl choice)
    thrift(nextNode, nextNode % 2 == 1, choice == height(node))
  }

  var node = 1
  while (node < n) {
    thrift(node, node % 2 == 1, (node + (1 shl height(node))) >= n)
    node += 1
  }

  node -= (node - 1) % 2
  while (node > 2) {
    for (child in height(node) - 1 downTo 0) {
      thrift(node - (1 shl child), false, true)
    }
    node -= 2
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
