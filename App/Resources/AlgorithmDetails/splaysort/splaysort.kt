class Node(
  var key: Int,
) {
  var left: Node? = null
  var right: Node? = null
}

fun leftRotate(x: Node): Node {
  val y = x.right!!
  x.right = y.left
  y.left = x
  return y
}

fun rightRotate(x: Node): Node {
  val y = x.left!!
  x.left = y.right
  y.right = x
  return y
}

fun splay(rootArg: Node?, key: Int): Node? {
  if (rootArg == null) {
    return rootArg
  }
  var root = rootArg
  if (root.key > key) {
    if (root.left == null) {
      return root
    }
    if (root.left!!.key > key) {
      root.left!!.left = splay(root.left!!.left, key)
      root = rightRotate(root)
    } else {
      root.left!!.right = splay(root.left!!.right, key)
      if (root.left!!.right != null) {
        root.left = leftRotate(root.left!!)
      }
    }
    return if (root.left == null) root else rightRotate(root)
  } else {
    if (root.right == null) {
      return root
    }
    if (root.right!!.key > key) {
      root.right!!.left = splay(root.right!!.left, key)
      if (root.right!!.left != null) {
        root.right = rightRotate(root.right!!)
      }
    } else {
      root.right!!.right = splay(root.right!!.right, key)
      root = leftRotate(root)
    }
    return if (root.right == null) root else leftRotate(root)
  }
}

fun insertRec(rootArg: Node?, key: Int): Node {
  if (rootArg == null) {
    return Node(key)
  }
  val root = splay(rootArg, key)!!
  val n = Node(key)
  if (root.key > key) {
    n.right = root
    n.left = root.left
    root.left = null
  } else {
    n.left = root
    n.right = root.right
    root.right = null
  }
  return n
}

fun sort(arr: Array<Int>) {
  var root: Node? = null
  for (x in arr) {
    root = insertRec(root, x)
  }
  val result = mutableListOf<Int>()

  fun traverse(node: Node?) {
    if (node != null) {
      traverse(node.left)
      result.add(node.key)
      traverse(node.right)
    }
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
