class Node(
  val value: Int,
) {
  var level: Int = 0
  var left: Node? = null
  var right: Node? = null
}

fun level(node: Node?): Int = node?.level ?: -1

fun skew(node: Node): Node {
  val l = node.left ?: return node
  node.left = l.right
  l.right = node
  return l
}

fun split(node: Node): Node {
  val r = node.right ?: return node
  node.right = r.left
  r.left = node
  r.level++
  return r
}

fun add(node: Node?, value: Int): Node {
  if (node == null) {
    return Node(value)
  }
  if (value < node.value) {
    node.left = add(node.left, value)
    if (level(node.left) == node.level) {
      if (node.level != level(node.right)) {
        return skew(node)
      }
      node.level++
      return node
    }
    return node
  } else {
    node.right = add(node.right, value)
    if (level(node.right?.right) == node.level) {
      return split(node)
    }
    return node
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  var root: Node? = null

  for (i in 0 until n) {
    root = add(root, arr[i])
  }

  val result = mutableListOf<Int>()

  fun traverse(node: Node?) {
    if (node == null) return
    traverse(node.left)
    result.add(node.value)
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
