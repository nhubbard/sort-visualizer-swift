class Node(
  val pointer: Int,
) {
  var left: Node? = null
  var right: Node? = null
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  var root: Node? = null

  fun add(node: Node?, addPtr: Int): Node {
    if (node == null) {
      return Node(addPtr)
    }
    if (arr[addPtr] < arr[node.pointer]) {
      node.left = add(node.left, addPtr)
    } else {
      node.right = add(node.right, addPtr)
    }
    return node
  }

  for (i in 0 until n) {
    root = add(root, i)
  }

  val result = mutableListOf<Int>()

  fun traverse(node: Node?) {
    if (node == null) return
    traverse(node.left)
    result.add(arr[node.pointer])
    traverse(node.right)
  }

  traverse(root)

  for (i in 0 until n) {
    arr[i] = result[i]
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
