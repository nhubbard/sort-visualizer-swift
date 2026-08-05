fun ceilPow2(value: Int): Int {
  var r = 1
  while (r < value) r *= 2
  return r
}

fun sort(array: IntArray) {
  val n = array.size
  if (n <= 1) return

  val size = ceilPow2(n) - 1
  val mod = n % 2
  val treeSize = n + size + mod
  val tree = IntArray(treeSize) { -1 }

  fun treeCompare(a: Int, b: Int): Boolean = array[tree[a]] <= array[tree[b]]

  for (i in size until treeSize - mod) {
    tree[i] = i - size
  }

  var j = size
  var k = treeSize - mod
  while (j > 0) {
    var i = j
    while (i + 1 < k) {
      tree[i / 2] = if (treeCompare(i, i + 1)) tree[i] else tree[i + 1]
      i += 2
    }
    if (i < k) {
      tree[i / 2] = tree[i]
    }
    j /= 2
    k /= 2
  }

  fun findNext(): Int {
    var path = tree[0] + size
    while (path > 0) {
      tree[path] = -1
      path = (path - 1) / 2
    }

    var node = tree[0] + size
    while (node > 0) {
      val sibling = if (node % 2 == 1) node + 1 else node - 1
      val nodeValid = tree[node] != -1
      val siblingValid = tree[sibling] != -1
      val winner =
        if (nodeValid && siblingValid) {
          if (node < sibling) {
            if (treeCompare(node, sibling)) tree[node] else tree[sibling]
          } else {
            if (treeCompare(sibling, node)) tree[sibling] else tree[node]
          }
        } else if (nodeValid) {
          tree[node]
        } else if (siblingValid) {
          tree[sibling]
        } else {
          -1
        }
      node = (node - 1) / 2
      if (winner != -1) {
        tree[node] = winner
      }
    }
    return array[tree[0]]
  }

  val output = IntArray(n)
  output[0] = array[tree[0]]
  for (i in 1 until n) {
    output[i] = findNext()
  }
  for (i in 0 until n) {
    array[i] = output[i]
  }
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println(array.joinToString(", ", "[", "]"))
}
