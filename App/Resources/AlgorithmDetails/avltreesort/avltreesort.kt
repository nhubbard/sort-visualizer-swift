class Node(
  val value: Int,
) {
  var left: Node? = null
  var right: Node? = null
  var balance = 0
}

class AddResult(
  val node: Node,
  val heightChanged: Boolean,
)

fun singleRotateRight(node: Node): Node {
  val b = node.left!!
  node.left = b.right
  b.right = node
  node.balance = 0
  b.balance = 0
  return b
}

fun singleRotateLeft(node: Node): Node {
  val b = node.right!!
  node.right = b.left
  b.left = node
  node.balance = 0
  b.balance = 0
  return b
}

fun doubleRotateRight(node: Node): Node {
  val oldBBalance = node.left!!.right!!.balance
  node.left = singleRotateLeft(node.left!!)
  val b = singleRotateRight(node)
  if (oldBBalance == -1) b.right!!.balance = 1
  if (oldBBalance == 1) b.left!!.balance = -1
  return b
}

fun doubleRotateLeft(node: Node): Node {
  val oldBBalance = node.right!!.left!!.balance
  node.right = singleRotateRight(node.right!!)
  val b = singleRotateLeft(node)
  if (oldBBalance == -1) b.right!!.balance = 1
  if (oldBBalance == 1) b.left!!.balance = -1
  return b
}

fun heightChangeLeft(node: Node): AddResult {
  if (node.balance != -1) {
    node.balance -= 1
    return AddResult(node, node.balance == -1)
  }
  if (node.left!!.balance == -1) {
    return AddResult(singleRotateRight(node), false)
  }
  return AddResult(doubleRotateRight(node), false)
}

fun heightChangeRight(node: Node): AddResult {
  if (node.balance != 1) {
    node.balance += 1
    return AddResult(node, node.balance == 1)
  }
  if (node.right!!.balance == 1) {
    return AddResult(singleRotateLeft(node), false)
  }
  return AddResult(doubleRotateLeft(node), false)
}

fun add(node: Node?, value: Int): AddResult {
  if (node == null) {
    return AddResult(Node(value), true)
  }
  if (value < node.value) {
    val result = add(node.left, value)
    node.left = result.node
    if (result.heightChanged) {
      return heightChangeLeft(node)
    }
    return AddResult(node, false)
  } else {
    val result = add(node.right, value)
    node.right = result.node
    if (result.heightChanged) {
      return heightChangeRight(node)
    }
    return AddResult(node, false)
  }
}

fun sort(arr: Array<Int>) {
  var root: Node? = null
  for (value in arr) {
    root = add(root, value).node
  }

  val result = mutableListOf<Int>()

  fun traverse(node: Node?) {
    if (node == null) return
    traverse(node.left)
    result.add(node.value)
    traverse(node.right)
  }

  traverse(root)

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
