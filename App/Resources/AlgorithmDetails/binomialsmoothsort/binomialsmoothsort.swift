func sort(_ arr: inout [Int]) {
  let n = arr.count

  func height(_ node: Int) -> Int {
    var count = 0
    while (node >> count) % 2 == 1 {
      count += 1
    }
    return count
  }

  func thrift(_ node: Int, _ parentFlag: Bool, _ rootFlag: Bool) {
    let isRoot = rootFlag && (node >= (1 << height(node)))
    if !isRoot && !parentFlag {
      return
    }

    var choice = height(node) - (isRoot ? 0 : 1)
    if parentFlag {
      var child = choice - 1
      while child >= 0 {
        if arr[node - (1 << choice)] <= arr[node - (1 << child)] {
          choice = child
        }
        child -= 1
      }
    }

    if arr[node - (1 << choice)] <= arr[node] {
      return
    }

    arr.swapAt(node, node - (1 << choice))
    let nextNode = node - (1 << choice)
    thrift(nextNode, nextNode % 2 == 1, choice == height(node))
  }

  var node = 1
  while node < n {
    thrift(node, node % 2 == 1, (node + (1 << height(node))) >= n)
    node += 1
  }

  node -= (node - 1) % 2
  while node > 2 {
    var child = height(node) - 1
    while child >= 0 {
      thrift(node - (1 << child), false, true)
      child -= 1
    }
    node -= 2
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
