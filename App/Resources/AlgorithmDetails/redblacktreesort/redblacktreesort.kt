class Node(
  val value: Int,
) {
  var left: Node? = null
  var right: Node? = null
  var isRed: Boolean = true
}

class AddResult(
  val node: Node,
  val needsFix: Boolean,
)

fun isRed(node: Node?): Boolean = node?.isRed ?: false

fun singleRotateRight(node: Node): Node {
  val b = node.left!!
  node.left = b.right
  b.right = node
  b.isRed = false
  node.isRed = true
  return b
}

fun singleRotateLeft(node: Node): Node {
  val b = node.right!!
  node.right = b.left
  b.left = node
  b.isRed = false
  node.isRed = true
  return b
}

fun doubleRotateRight(node: Node): Node {
  node.left = singleRotateLeft(node.left!!)
  return singleRotateRight(node)
}

fun doubleRotateLeft(node: Node): Node {
  node.right = singleRotateRight(node.right!!)
  return singleRotateLeft(node)
}

fun add(node: Node?, value: Int): AddResult {
  if (node == null) {
    return AddResult(Node(value), false)
  }

  if (!node.isRed && isRed(node.left) && isRed(node.right)) {
    node.isRed = true
    node.left!!.isRed = false
    node.right!!.isRed = false
  }

  if (value < node.value) {
    val child = add(node.left, value)
    node.left = child.node
    if (child.needsFix) {
      if (isRed(node.left!!.left)) {
        return AddResult(singleRotateRight(node), false)
      }
      return AddResult(doubleRotateRight(node), false)
    }
    return AddResult(node, node.isRed && isRed(node.left))
  } else {
    val child = add(node.right, value)
    node.right = child.node
    if (child.needsFix) {
      if (isRed(node.right!!.right)) {
        return AddResult(singleRotateLeft(node), false)
      }
      return AddResult(doubleRotateLeft(node), false)
    }
    return AddResult(node, node.isRed && isRed(node.right))
  }
}

fun traverse(node: Node?, result: MutableList<Int>) {
  if (node == null) return
  traverse(node.left, result)
  result.add(node.value)
  traverse(node.right, result)
}

fun sort(arr: Array<Int>) {
  var root: Node? = null
  for (v in arr) {
    val inserted = add(root, v)
    root = inserted.node
    root.isRed = false
  }

  val result = mutableListOf<Int>()
  traverse(root, result)

  for (i in arr.indices) {
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
